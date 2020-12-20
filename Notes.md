# Notes

The goal here is to make a Pluto notebook "viewer" that runs Julia so the notebook is live. I investigated two free services: [Heroku](http://heroku.com/) and [binder](https://mybinder.org). I settled on Heroku with a docker image as the most performant solution (the free nodes are very underpowered and so the time to loaded notebook can be long).

## Heroku with docker image

See the [Container Registry & Runtime (Docker Deploys)](https://devcenter.heroku.com/articles/container-registry-and-runtime) documentation page. I made a docker image that has Julia as well as the notebook files with their data that I want viewable (you can have Pluto open notebooks using a URL as well). The packages my notebooks use are all in `Project.toml/Manifest.toml` files at the top level of the repository. Building the docker image will instantiate and precompile them (would be better to build a shared object). Here are the steps I follow to deploy (note that I'm using the Heroku CLI),

- Login with `heroku container:login`.

- `cd` to the top of the git repository

- Run `heroku create` (only once).

- Build the image on Heroku with `heroku container:push web`.

    - Instead of building on Heroku, you can build the image locally and upload to Heroku. See [here](https://devcenter.heroku.com/articles/container-registry-and-runtime#pushing-an-existing-image). Building on Heroku is likely faster than building/pushing locally in the long run since you won't have to upload everything to Heroku.

- Release the image to the app with `heroku container:release web`. The app is now live on Heroku.

- View it in your browser with `heroku open`. It will take a minute or two before the app responds.

You can look at log info with `heroku logs [--tail]`. You can see if the dyno is up and your free quota with `heroku ps`. Note that `heroku ps:exec` does not work (apparently that only works on slugs).

If you see [`R14` errors](https://devcenter.heroku.com/articles/error-codes#r14-memory-quota-exceeded) in the log it means that Julia is swapping.

## Other solutions considered

- Heroku slugs: The normal way to run Heroku is with a `slug`. That is to run a script within a Heroku pre-defined language *buildpack*. Heroku doesn't have a buildpack for Julia, but one is [here](https://github.com/mbauman/heroku-buildpack-julia). The [CovidCountyDash](http://covid-county-dash.herokuapp.com) [application](https://github.com/mbauman/CovidCountyDash.jl) runs as a slug. The problem with slugs is that their size for the free tier cannot exceed 500 MB. This is too small to run my Pluto notebook. Docker images in Heroku have no size limit.

- MyBinder: MyBinder is geared for running Jupyter notebooks. There is [pluto-on-binder](https://github.com/fonsp/pluto-on-binder) that uses [jupyter-server-proxy](https://jupyter-server-proxy.readthedocs.io/en/latest/) to run arbitrary external processes. I could even use a pre-existing instance of `pluto-on-binder` [here](https://pluto-on-binder.glitch.me) that can open a notebook at a URL. The problem here is speed. The notebook needs to download and install its dependent packages and it takes a very long time ... too long to be usable.

## Things to try

Have the docker file make a shared object with [PackageCompiler](https://github.com/JuliaLang/PackageCompiler.jl). That will likely reduce memory usage and should speed things up.
