# The Phlox Architecture

> *"A picture is worth a thousand words"*

...but yet, we often write tens of thousands of lines of code without any visual documentation.

The Phlox architecture helps you build a frontend in a way that is easy to **visualize**.
The goal is that you should be able to draw a simple "box and line" diagram showing the components and dependencies in your code.

By looking at such a diagram you should be able to answer questions like:

- From how many places are we calling the create-user endpoint in the REST-api?
- How many views in our app are using any user-related data?
- ...

The diagram below is from the example in [examples/restaurant-reviewer](...)
[example picture]


*This repo is both a description of the phlox architecture as well as a simple implementation of the architecture. It also contains react-bindnings so you can use it in a react project.*

# How does it work?
A phlox arcitecture is made up of 5 different types of components; *queriers*, *lifters*, *models*, *invokers* and a *parser*. These all have quite a narrow responsability and they can be written in a fairly declarative way. Because of this, it's possible to visualize them and their dependencies in a diagram.

Let's go through the different parts of phlox!

## Queriers
- **Responsability:** to produce a query for requesting some data that the application needs
- **Input:** application state (including lifted state)
- **Output:** a query to request data
- **Meta:**
	- a key or path to where the data should be put once received
	- a list of the queriers dependencies on the application state (typically a list of keys or paths)
- **Example:** request users from the server and put it under "state.users"

## Lifters
- **Responsability:** to select / combine / denormalize data
- **Input:** application state
- **Output:** denormalized or "lifted" data
- **Meta:**
	- a key or path to where to put that data
	- a list of the lifters dependencies on the application state (typically a list of keys or paths)
- **Example:** filter out employees that has `department = 'sales'`, sort them on name and add data about their sales from the sales data that lies in another part of the application state
- **Note:** comparable to selectors in re-select

## Invokers
- **Responsability:** to produce a "short lived" query to change something when needed
- **Input:** application state
- **Output:** a query to do whatever is necessary
- **Meta:**
	- a list of the invokers dependencies on the application state (typically a list of keys or paths)
- **Example:** To select a default date in a day view when arriving to it the first time without any selected date. Or to redirect a user to /login if no session cookie is found.
- **Note:** The difference between queriers and invokers is that the query produced by a querier is suppose to request data and can be seen as "long lived", i.e. the data is requested and should exist until the querier produces a new data query. A query produced by an invoker should probably not request for data but rather be a mutative query to change something as a response to a specific application state. 

## View Models
- **Responsability:** to 
- **Note:** The concept of having a model for a view is taken from Elm.






# Implementation

This is an implementation of the [phlox architecture](...).

# React bindings

# Example usage

### How do you handle normalization and denormalisation?

### How do you handle client-side redirects?

### How do you handle complex mutative actions?

