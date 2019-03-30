# Project Template

This is a project template used for a diverse set of web projects that use docker.

This project structure along with the dev enviroment setup allows for mutiple websites to be ran on your local dev box. Each can have there own .test domain that will point to the correct containers with out needing to manage ports or domains.

## Folder structure

repo
 - app1
   - tech1 (eg apache)
   - tech2 (eg php)
   - tech3 (eg redis)
 - app2
   - tech1 (eg python3)

## Dev Enviroment Setup
The dev enviroment is described in [DEVENV.md](DEVENV.md)