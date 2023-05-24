# Simple API

This repository contains a simple API that provides two endpoints for retrieving information. The first endpoint displays the current timestamp in Unix format, while the second endpoint generates a list of 10 random numbers within the range of 0 to 5.

## Running the Application Locally

To run the application on your local machine, follow these steps:

1. Build the Docker image by executing the following command:

```
docker build -t simple-api .
```

Alternatively, you can directly pull the image from the public registry using this command:

```
docker pull harithj/simple-api
```

2. Start the application by running the Docker container. If you built the image locally, use this command:

```
docker run -p 8080:80 simple-api
```

If you pulled the image from the public registry, use this command instead:

```
docker run -p 8080:80 harithj/simple-api
```

3. You can now access the application in your web browser by visiting `localhost:8080`.

## Accessing the Endpoints

The application exposes two endpoints:

1. **/time**: This endpoint returns the current Unix timestamp.

2. **/random**: This endpoint generates a list of 10 random numbers within the range of 0 to 5.

Feel free to use these endpoints to retrieve the desired information from the API.
