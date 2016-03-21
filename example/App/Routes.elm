module App.Routes where

type Route = Home | NotFound | Static String | Category | Post

routes : List Route
routes = [NotFound, Static "about", Static "contacts", Home, Category, Post]
