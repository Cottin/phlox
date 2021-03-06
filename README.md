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
A phlox arcitecture is made up of 4 different concepts; *ui*, *queries*, *lifters*, and *invokers*. These four things can be written in a fairly declarative way and because of this, it's possible to visualize them and their dependencies in a diagram.
