module Router.Types exposing (..)

{-| Router types

# URL parts
@docs URL, RawURL, RawSegment, Param, Constraint, Route, RouteConfig, RouteParams

# Actions and handlers
@docs WithRouter, Handler, Action, Commands, Response, Transition

# Router
@docs Router, RouterConfig, RouterState
-}

import Dict           exposing (Dict)
import Html           exposing (Html)

-----------------------------------------
-- Route mather related types
-----------------------------------------

{-| A valid URL:
```
"/home/post/1"
```
-}
type alias URL = String

{-| Raw URL template:
```
"/home/post/:postId"
```
-}
type alias RawURL = String

{-| A single segment of `RawURL` template -}
type alias RawSegment = String

{-| Dynamic route parameter name -}
type alias Param = String

{-| A map of route param names and values -}
type alias RouteParams  = Dict Param String

{-| A constraint of route parameter type -}
type Constraint = Int | String | Enum (List String) | Regex String

{-| combined abstract route type with params -}
type alias Route route = (route, RouteParams)

-----------------------------------------
-- Handler related types
-----------------------------------------

{-| An action result - a modified state combined with side effects -}
type Response state = Response (state, Commands state)

{-| `Action` represents function that prforms something with application state, and might contain side efects -}
type alias Action state = state -> Response state

{-| Helper to get rid of brackets -}
type alias Commands state = Cmd (Action state)

{-|
  A `Handler` is a piece of functionality binded to specific route
  * `view` &mdash; Function that describes how to render application state to map of named views
  * `actions` &mdash; A set of necessary to perform actions
-}
type alias Handler state = {
    view: state -> Dict String (Html (Action state)) -> Dict String (Html (Action state))
  , actions: List (Action state)
  }

{-|
  `RouteConfig` is a route configuration

  * `segment` &mdash; URL segment

  Expample:
```
"/home",
"/post/:postId",
"/author[/:authorId]"
```
  * `parent` &mdash; A parent route
  * `bypass` &mdash; When setted to True - route will not be matched directly, but still can provide actions and views
  * `constraints` &mdash; A set of constraints applied to route params. (`String`, `Int`, `Enum`, `Regexp`) constraints are supported
  * `handler` &mdash; A binding to handler.

  **Exapmle of route configuration**:
```
  config = {
    -- "author" and "postId" is dynamic url parts
    -- "postId" is marked as optional and might me ommited in URL
    segment = "/page/:author[/:postId]"
  , parent = Nothing
    -- setting a parent for route means that full route URL will be combined with it's parent, and actions for route and it's parent will be fired on match
  , bypass = False
  , constraints = Dict.fromList [("author", String),("postId", Int)]
    -- constraints specify that `author` param must be a string,
    -- and postId an integer
  , handler = always PostHandler
  }
```

  A `config` above will match following URLs:
```
"/page/mark/1", "/page/mark", "/page/joe"
```
  "mark" and "joe" will be stored as `author` param, and "1" as `postId`
  Everything enclosed by brackets considered as optional.
-}
type alias RouteConfig route state = {
    segment: RawSegment
  , parent: Maybe route
  , bypass: Bool
  , constraints: Dict Param Constraint
  , handler: Router route state -> Handler state
  }

{-| A state of router -}
type alias RouterState route = {
    route: Maybe route
  , params: RouteParams
  }

{-| Type extension for the application state -}
type alias WithRouter route state = { state | router : RouterState route}

{-| A transition from route A to route B -}
type alias Transition route state = Maybe (Route route) -> Maybe (Route route) -> Action state

{-|
  `RouterConfig` is configuration for the router:

  * `html5` &mdash; Use html5 pushState.
  * `removeTrailingSlash` &mdash; Trailing slashes will be removed from matched and builded urls
  * `layout` &mdash; Main rendered function that combines named views gathered from Handlers in a single HTML
  * `transition` &mdash; An action that should be executed on every router transition
  * `routeConfig` &mdash; A mapping between route and route configuration
  * `routes` &mdash; A list of routes available for routing
  * `subscriptions` &mdash; A list of subscriptions (see: [elm-lang/html](http://package.elm-lang.org/packages/elm-lang/html/1.1.0/Html-App) for details)
-}
type RouterConfig route state = RouterConfig {
    html5: Bool
  , removeTrailingSlash: Bool
  , layout: Router route state -> state -> Dict String (Html (Action state)) -> (Html (Action state))
  , transition: Router route state -> Transition route state
  , routeConfig: route -> RouteConfig route state
  , routes: List route
  , subscriptions : state -> Sub (Action state)
  }

{-|
  A `Router` is a provider of following functions:

  * `bindForward` &mdash; Binds a `forward` action to a provided `Route` with a list of html attributes.
    This is useful to create links in application
  * `buildUrl` &mdash; Builds an URL for provided `Route`
  * `forward` &mdash; Preforms a transition to provided `Route`
  * `redirect` &mdash; Redirects to provided `Route`
  * `match` &mdash; Performs attempt to match provided URL.

  Router also provide it's `config`
-}
type alias Router route state = {
    config : RouterConfig route state
  , bindForward : Route route -> List (Html.Attribute (Action state)) -> List (Html.Attribute (Action state))
  , buildUrl : Route route -> URL
  , forward : Route route -> Action state
  , redirect : Route route -> Action state
  , match : String -> Maybe (Route route)
  }
