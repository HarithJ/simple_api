import time
import random
from fastapi import FastAPI

app = FastAPI()


@app.get("/time")
async def root():
    # Get the current time in seconds since the Unix Epoch
    timestamp = time.time()
    return {"time": timestamp}


@app.get("/random")
async def root():
    # Generate a list of 10 random numbers in the range of 0 to 5
    random_numbers = [random.randint(0, 5) for _ in range(10)]
    return {"random_numbers": random_numbers}
