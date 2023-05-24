# Get all available zones
data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "aws_vpc" "simple_app" {
  cidr_block = "10.32.0.0/16"
}

resource "aws_subnet" "public" {
  count                   = 2

  # take the original CIDR block of the VPC, extend it by 8 bits, and then adds the index (0 or 1 in this case)
  # 10.32.0.0/24
  # 10.32.1.0/24
  cidr_block              = cidrsubnet(aws_vpc.simple_app.cidr_block, 8, count.index)

  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.simple_app.id

  # automatically assign IP addresses to instances on launch
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = 2

  # take the original CIDR block of the VPC, extend it by 8 bits, and then adds the index+2 (2 or 3 in this case)
  # 10.32.2.0/24
  # 10.32.3.0/24
  cidr_block        = cidrsubnet(aws_vpc.simple_app.cidr_block, 8, count.index + 2)

  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.simple_app.id
}

# Internet Gateway is a logical connection between an Amazon VPC and the Internet
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.simple_app.id
}

# Creates a route in the main routing table for the VPC to direct all traffic to the Internet Gateway.
# This allows instances in the public subnets to access the internet.
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.simple_app.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

# Create 2 Elastic IP addresses for NAT Gateways
resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

# creates 2 NAT Gateways, one under each public subnet and each associated with Elastic IP address
# NAT Gateway allows instances in private subnets to communicate with the internet but prevents the internet from initiating connections
resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

# Create 2 routing tables, one for each private subnet
# Each routing table has a single route directing all traffic to each NAT Gateway
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.simple_app.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

# Associate each of the private subnets with one of the newly created routing tables
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

# Allow inbound HTTP traffic (TCP port 80) from any IP address (0.0.0.0/0)
# and allow all outbound traffic (protocol = -1 means all protocols)
resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  vpc_id      = aws_vpc.simple_app.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a LB in public subnets and attach SGs
resource "aws_lb" "lb" {
  name            = "simple-lb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

# set up target group to route HTTP traffic on port 80
resource "aws_lb_target_group" "simple_app" {
  name        = "simple-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.simple_app.id
  target_type = "ip"
}

# set up listener for HTTP traffic on port 80 and forward them to target group
resource "aws_lb_listener" "simple_app" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.simple_app.arn
    type             = "forward"
  }
}

# Create ECS task and run the app container
resource "aws_ecs_task_definition" "simple_app" {
  family                   = "simple-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<DEFINITION
[
  {
    "image": "harithj/simple-app",
    "cpu": 1024,
    "memory": 2048,
    "name": "simple-app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
}

# SG for ECS service
resource "aws_security_group" "simple_app_sg" {
  name        = "simple-app-security-group"
  vpc_id      = aws_vpc.simple_app.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    # allow traffic from the load balancer to the ECS
    security_groups = [aws_security_group.lb_sg]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "simple-cluster"
}

# Create ECS service within the cluster
resource "aws_ecs_service" "simple_app" {
  name            = "simple-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.simple_app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.simple_app_sg.id]
    subnets         = aws_subnet.private.*.id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.simple_app.arn
    container_name   = "simple-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.simple_app]
}
