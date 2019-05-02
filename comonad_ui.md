---
title: Comonadic Interface Design
subtitle: Potentially the next big thing
author: Mitch Stevens
theme: Boadilla
---


# Comonads
- **Comonads** are dual structure to Monads
- Monads express effectful computations
- Comonads are values in some context

```haskell
class Comonad w where
  extract   :: w a -> a       -- copure
  duplicate :: w a -> w (w a) -- cojoin
```

<!-- Or that a value can be obtained -->
<!-- You've already got an a, you can extract it out at anytime. But there is a whole bunch of information AROUND the value that is also useful -->

# Extracting and Duplicating
- Comonads can be seen as a state transition diagram [^#]
- Using `extract`, we can extract the value that we were focusing on
<!-- extract is pretty intuitive here -->

![A Scomonad focused on something](angry-scott-morrison.jpg){ width=30% }

. . .

- `duplicate` explodes out all the states of the transition
<!-- This is less obvious, some examples will be needed if you have never seena comonad before. -->

[^#]: https://blog.functorial.com/posts/2016-08-07-Comonads-As-Spaces.html

# NonEmpty List
```haskell
data NonEmptyList a = NonEmptyList a [a]

tail :: NonEmptyList a -> NonEmptyList a
tail (NonEmptyList _ xs) = NonEmptyList (head xs) (tail xs)

instance Comonad Zipper where
  extract (NonEmptyList x xs) = x
  duplicate neList = NonEmptyList neList allTails
    where ...
```


# NonEmpty Graph as a Comonad
```haskell
data NEGraph a = -- Complicated Stuff here

focusUpon :: NEGraph a -> a -> NEGraph a
focusUpon graph focus = -- TODO: focusUpon 

instance Comonad NEGraph where
    extract = -- TODO: extract
    duplicate graph = fmap (focusUpon graph) graph

```

# Other Comonads
- `Identity a`
- `(e, a)`
- Zippers
- `Trees with values in the branches (Cofree f)`
<!-- Some trees have values at the branches, some have values at the edges -->



# Kliesli and Cokliesli
<!-- So what else can we do with comonads? -->
- A function `a -> m b` is called a Kliesli arrow
- If `m` is a monad, we get Kliesli composition for free
```haskell
(>=>) :: (a -> m b) -> (b -> m c) -> (a -> m c)
```

. . .

- The dual to a Kliesli arrow is a Cokliesli arrow
- If `w` is a comonad, we also get Cokliesli composition
```haskell
(=>=) :: (w a -> b) -> (w b -> c) -> (w a -> c)
```


# Uses for Comonads
Image processing is a natural fit for Cokliesli composition[^#]

we can focus on


```haskell
render :: FocusedImage Pixel -> Image
blur :: FocusedImage Pixel -> Pixel
lighten :: FocusedImage Pixel -> Pixel

lighten =>= blur =>= render
```

[^#]: https://jaspervdj.be/posts/2014-11-27-comonads-image-processing.html


# What is a UI?
* The only hard requirement is a rendering function...

. . .

* But we'll also need
    * Mutable state
    * initialiser, finaliser
    * preloaded data
    * other effects, etc

. . .

```haskell
data NaiveUI s h = UI
  { state :: s
  , render :: s -> h
  }
```

* This would allow us to `fmap` over `h` to render to something else.
* `UI` admits a comonad instance


# The store comonad
- The `NaiveUI` comonad is usually called `Store`

```haskell
data Store s a = Store (s -> a) s
instance Comonad (Store s) where
  extract (Store render state) = render state
  duplicate (Store render state)
    = Store (Store render) state

Store s (Store s a) = Store (s -> Store s a) s
```
<!-- The duplicate function looks something -->


# Components using Comonads
```haskell
type Component w = Comonad w => w (UI ())
```
* `extract` will render the component
* `duplicate` will explore future states of a component
<!-- Draw up type of `Store s (Store s a)`, explain how this represents exploration -->

```haskell
extract :: Component w -> UI ()               -- render
duplicate :: Component w -> w (Component w)   -- explode
select :: x -> w (Component w) -> Component w -- choose
```
<!-- Here we have `duplicate` (explosion) and `select`. -->
<!-- `select` is a function that takes something that selects a posible future from the model of all posible futures `w (w a)`, using a type called `x`.  -->
<!-- It's not clear that we can write a general `select` function that does what we want, or what `x` should be. We can start by saying that it should depend on `w` -->


# Adjunctions
 - An adjuction is a relationship between two functors `f` and `g`.

```haskell
-- from Data.Functor.Adjunction (simplified)
class (Functor f, Functor g) => Adjunction f u where
  leftAdjunct :: (f a -> b) -> a -> g b
  rightAdjunct :: (a -> g b) -> f a -> b
```

- We call this relationship an **Adjunction**
<!-- Or we say that f and g are Adjoint -->
- There are also a set of Adjunction laws

- If we require `Monad g` and `Comonad f`, this is looks like an isomorphism between `Kliesli g` and `Cokliesli f`...


<!-- # Adjunctions
We don't get full isomorphism between the two, the adjoint laws are not strong enough.

So what do we get then?

```haskell
unit   :: Adjunction w m => a -> m (w a)
counit :: Adjunction w m => w (m a) -> a
``` -->


# Examples of Monad/Comonad Adjunctions

| Monad      | Comonad    |
| ---------- | ---------- |
| `Identity` | `Identity` |
| `Reader r` | `Env r`    |
| `State s`  | `Store s`  |
| `Writer w` | `Traced w` |
| `Free f`   | `Cofree f` |


We also have an adjuction between monad/comonad transformers
```haskell
instance Adjunction w m =>
  instance Adjunction (EnvT r w) (ReaderT r m)
```


# The Reader/Env Pairing
```haskell
type Reader r a = r -> a -- Monad m
type Env    r a = (a, r) -- Comonad w
```

. . .

Adjunction requirements:
```haskell
(w a -> b) -> (a -> m b)
(a -> m b) -> (w a -> b)
```
<!-- Go through the algebra to show that 1 is curry and 2 is uncurry -->


# An utterly surprising result! 
`m ()` can be used to navigate through `w a`

```haskell
select :: Adjunction w m => m () -> w (w a) -> w a
```

<!-- Go over example with the store monad -->

. . .

If `w` has a right adjunct `m`, we get a navigation type for free


# Overview
We have developed a way of 


```haskell
extract :: Component w -> UI ()                  -- render
duplicate :: Component w -> w (Component w)      -- explode
select :: m () -> w (Component w) -> Component w -- choose
```



# Applications
We want to be able to compose comonadic components

> The limerick packs laughs anatomical
> In space that is quite economical.
>    But the good ones I've seen
>    So seldom are clean
> And the clean ones so seldom are comical


# Comonadic Sum
~~~
data A f a =
  A (m x -> b) (f x)
~~~

# Comonadic Product
Use case

```haskell
data Day f g a =
  Day (x -> y -> a) (f x) (g y)
instance Comonad f, Comonad g => Comonad (Day f g)
```


# Homogenous Transformers
## Monad Transformers
```haskell
class MonadTrans t where
  lift :: Monad m => m a -> t m a
```

. . .

## Comonad Transformers
```haskell
class ComonadTrans t where
  lower :: Comonad w => t w a -> t a
```

# Co
`Co` is a heterogenous transformer

```haskell
data Co w a = Co { unCo :: w (a -> r) -> r }
instance Comonad w => Monad (Co w) where ...
```

. . .

Given a comonad `w`, `Co w` is a monad

. . .

Whats more, this new monad `Co w` is right adjunct to `w`, meaning we get a way to move around `w a` for free.


# Co Zipper
Zippers are an example of an comonad with no obvious monad pairing.[^#]
<!-- Using Co to movearound the space of the zipper is a good choice here -->


```haskell
left :: Zipper a -> Zipper a
left (Zipper (l:ls) v rs) = Zipper ls l (v:rs)

-- type Co Zipper a = Co (Zipper (a -> r) -> r)

moveLeft :: Co Zipper ()
moveLeft = Co $ \z -> extract (left z) ()
```


[^#]: A Real-World Application with a Comonadic User Interface, Arthur Xavier, 2018


# Handling arbitrary effects
Given that `Co w` is a monad, why not add another parameter `m` for effects

```haskell 
newtype CoT w m a = CoT { runCoT :: w (a -> m r) -> m r }
```

# Message Passing
- Use Free Monads:
    - Functor `QueryF a` to model messages to a component
    - `eval :: Free QueryF a -> m a` evaluates these messages
- 

# Interesting Ideas
- Comonad transformer stacks
- `Day f` is isomorphic to `f`

