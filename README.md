# Klimaschutz Monitor

Klimaschutzaktivitäten einer Kommune sollten kritisch begleitet und überwacht werden. Der Klimaschutz Monitor bietet eine Möglichkeit, die geplanten Maßnahmen übersichtlich und nach Sektoren gruppiert darzustellen. Der aktuelle Status kann schnell von Betrachtenden erfasst werden.

## Status

Dies ist eine Demo, mit der das Prinzip verdeutlicht werden soll. Es wäre schön, wenn sich in den Issues nach und nach konkrete Verbesserungsvorschläge ansammeln. Derzeit ist die Entwicklungskapazität stark eingeschränkt. Das könnte sich aber schnell ändern, wenn ich finanziell unterstützt werde.

## Eingabe von Inhalten

Derzeit können die Inhalte mithilfe von Formularen bearbeitet werden. Im folgenden Video wird das einmal demonstriert:

https://user-images.githubusercontent.com/31070920/211902138-3dc14a51-e43a-464d-a84e-f68ed3fa8f4b.mp4

Wenn Du Interesse hast, damit Daten einzugeben, brauchst Du ein GitHub Konto. Diesem Konto kann ich dann die Bearbeitung erlauben.

Danach erreichst Du die Formulare über diesen Link: <https://mdrie.github.io/klimaschutzmonitor/admin/>.

## Development

Everything related to development is written in English.

The frontend is written in [Elm](https://elm-lang.org/) using [Elm Pages](https://elm-pages.com/) for static site generation.
[Netlify CMS](https://www.netlifycms.org/) is used for entering the content. (This will be replaced by [Static CMS](https://staticjscms.netlify.app/) soon.)

### Start Development Server

Prerequisite: [node.js](https://nodejs.org) (A rather current version should work. I currently use 18.9.0.)
Prepare a local copy with

```sh
git clone https://github.com/mdrie/klimaschutzmonitor
npm install
```

(Or use an IDE with node/npm support )

This will install Elm, Netlify CMS and a few other tools used for development.

A development server can be started with

```sh
npm run start
```

This will show a link, which you can open in your browser, e.g.

```sh
elm-pages dev server running at <http://localhost:1234>
```

### Start CMS

The CMS can be started with

```sh
npm run cms:serve
```

This will also show a link, e.g.

```sh
➜  Local:   http://localhost:5173/
```

**Note:** The CMS will now still edit the content on GitHub directly, requiring authorization and causing a pull request for every time you click a "Save" button.

### CMS for Editing Locally

Change the file `public/admin/config.yml` by toggling the comments in the `backend:` section. Comment the GitHub configuration and `publish_mode` and uncomment the `git-gateway` and `local_backend` to read:

```yaml
backend:
  #name: github
  #repo: mdrie/klimaschutzmonitor
  #branch: main
  name: git-gateway
local_backend: true
#publish_mode: editorial_workflow
```

PLEASE make sure not to push this change to GitHub.

Now you can run both the development server as above and in a separate shell the local CMS with:

```sh
npm run startcms
```

The CMS will not ask for a login and edit the local contents directly. Any changes in the CMS will be reflected immediately in the frontend. This is much more convenient when editing larger amounts.

It would be nice to have a separate `config.yml` for this, such that editing the file is not needed. However, then the collection configuration in the same file would be duplicated. Once we swithch to Static CMS (successor of Netlify CMS), this might improve.

### Deployment

To build run:

```sh
npm run build
```

This will produce the directory `dist`, which may be served with a web server or on a CDN. It can be served locally for testing with

```sh
npm run servebuild
```

This is performed for each push to the main branch on GitHub or any pull request. If it succeeds on the main branch, it is automatically deployed to <https://mdrie.github.io/klimaschutzmonitor/>.
