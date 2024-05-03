# Scrippy

Scrippy helps you run a specific command in all the first level directories within a directory. This is specially helpful when you are working on a project with multiple Microservice.

## Use case
Checkout the following scenario. You have a project `amazing` that contains 10 microservices and currently you are working on features `awesome` and `cool`. `awesome` resides in 3 microservices and `cool` is in 5. The features also have 2 microservices in common. You need to constantly switch between these features for development. This is where Scrippy comes in handy. Scippy can find, checkout to, pull or delete a specific git branch in multiple first level directories.

## Features
- Find a specific Git branch
- Checkout to a specific Git branch
- Pull a specific Git branch
- Delete a specific Git branch

## Installation
- Clone the repository.
- Copy the `.env.example` file to same directory as `.env`.
- Update the envs to your need in the `.env` file.
- Make the `.sh` files executable (`chmod +x <filename>.sh`).