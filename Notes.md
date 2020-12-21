# Notes

The goal here is to make a Pluto notebook "viewer" that runs Julia so the notebook is live. I investigated two free services: [Heroku](http://heroku.com/) and [binder](https://mybinder.org). I settled on Heroku with a docker image as the most performant solution (the free nodes are very underpowered and so the time to loaded notebook can be long).

## Heroku with docker image

See the [Container Registry & Runtime (Docker Deploys)](https://devcenter.heroku.com/articles/container-registry-and-runtime) documentation page. I made a docker image that has Julia as well as the notebook files with their data that I want viewable (you can have Pluto open notebooks using a URL as well). The packages my notebooks use are all in `Project.toml/Manifest.toml` files at the top level of the repository. Building the docker image will compile packages into a shared object that will be used by Julia in the container. Here are the steps I follow to deploy (note that I'm using the Heroku CLI and you must have docker installed locally),

- `cd` to the top of the git repository

- The build process will create a shared object with packages compiled by [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl). We need to setup the `precompile.jl` fille, made up of a file for `Pluto` and a file for each of your notebooks (these files have the function calls recorded that the compiler will use). Note that this will lock versions of these packages (that's likely a good thing). If you update the packages, you should regenerate the `precompile.jl` file with these instructions. Within the container, the julia base system image will be replaced with the generated image, ensuring that all julia instances will use it.

-  Make the `precompile-pluto.jl` script with,

```julia
julia --project=. --trace-compile=precompile-pluto.jl
import Pluto
Pluto.run()
# Load a notebook. Note that this will only record the Pluto calls, not the calls within the notebook (we'll do that next)
# Once the notebook is loaded, quit Pluto and exit Julia
```

- For each notebook in the repository you want available, generate a precompile script by running the notebook file (not within Pluto). For example (the dash after `precompile-` will be used to identify the constituent files)

```julia
cd IRMA-031-TimingStudy
julia --project=.. --trace-compile=../precompile-timingStudyPresent.jl timingStudyPresent.jl
```

  - Now merge the precompile scripts...

```bash
cat precompile-*.jl | sort | uniq > precompile.jl
```

  - You can discard the `precompile-*.jl` files.

- Login with `heroku container:login`.

- Run `heroku create` (only once).

- Build the image with `heroku container:push web`. This will build the image locally and then push to Heroku's repository. The `Dockerfile` is written such that a minor change to a notebook
will result in a very quick and small update to the docker image.

  - If you've already built the image, see [here](https://devcenter.heroku.com/articles/container-registry-and-runtime#pushing-an-existing-image).

- Release the image to the app with `heroku container:release web`. The app is now live on Heroku.

- View it in your browser with `heroku open`. It will take a minute or two before the app responds if the dyno is starting up.

You can look at log info with `heroku logs [--tail]`. You can see if the dyno is up and your free quota with `heroku ps`. Note that `heroku ps:exec` does not work (apparently that only works on slugs).

If you see [`R14` errors](https://devcenter.heroku.com/articles/error-codes#r14-memory-quota-exceeded) in the log it means that the VM is swapping and it will be slow (this happens at 500 MB of use). The VM will restart if you reach 1 GB of memory usage.

If you want to try the docker container locally, note that you must specify the port Pluto will use in an environment variable. For example,

```
docker run -p 127.0.0.1:5000:5000 -e PORT=5000 registry.heroku.com/enigmatic-dawn-62308/web
```

Then connect your browser to `localhost:5000`. Remember that any changes you make to the notebook will be lost when you exit the container, unless the notebook is on a volume you've mounted from your host filesystem.

## Other solutions considered

- Heroku slugs: The normal way to run Heroku is with a `slug`. That is to run a script within a Heroku pre-defined language *buildpack*. Heroku doesn't have a buildpack for Julia, but one is [here](https://github.com/mbauman/heroku-buildpack-julia). The [CovidCountyDash](http://covid-county-dash.herokuapp.com) [application](https://github.com/mbauman/CovidCountyDash.jl) runs as a slug. The problem with slugs is that their size for the free tier cannot exceed 500 MB. This is too small to run my Pluto notebook. Docker images in Heroku have no size limit.

- MyBinder: MyBinder is geared for running Jupyter notebooks. There is [pluto-on-binder](https://github.com/fonsp/pluto-on-binder) that uses [jupyter-server-proxy](https://jupyter-server-proxy.readthedocs.io/en/latest/) to run arbitrary external processes. I could even use a pre-existing instance of `pluto-on-binder` [here](https://pluto-on-binder.glitch.me) that can open a notebook at a URL. The problem here is speed. The notebook needs to download and install its dependent packages and it takes a very long time ... too long to be usable.
