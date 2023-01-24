# Todoish

![Todoish](https://user-images.githubusercontent.com/22826580/214425030-58798d72-2d1a-43c3-8a06-cec5cf001029.jpg)


A real time sharable todo-list! Built with Elixir, Phoenix, LiveView, and Ash.

Check out [Todoish live](https://todoi.sh/)!

---

## Development

1. Install Deps

```sh
mix deps.get
```

2. Setup Postgres on port `5455`
3. Setup DB
```sh
mix ash_postgres.create
mix ash_postgres.migrate
```

## Deploy

An instance of Todoish can be set up on fly from [this tutorial](https://fly.io/docs/elixir/).
