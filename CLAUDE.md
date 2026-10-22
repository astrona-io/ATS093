# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS093 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Production Operations, Security & Kubernetes**
  domain of the **Keycloak** training path (`ATP018`). It is 15% of the path.
  There is no official Keycloak certification exam; the path's domains and
  weights are Astrona's own, set in `ATP018/path.yaml`.
- **What the domain really tests:** running Keycloak on Kubernetes the way a
  production team does, not remembering words. The student must *do* things
  (write a `Keycloak` custom resource, read its status conditions, import a
  realm with the operator, scale to two instances and prove they form one
  cluster, put Keycloak behind a TLS-terminating proxy, switch on brute force
  detection and rate limiting, dump and restore the database, roll back a
  failed upgrade). Every explanation should lead to a command they can run,
  and every fix should be proved with a real request: a token, a discovery
  document through the proxy, a metric, or a realm that is back.
- **The four topics:** the Keycloak Operator, the database and clustering,
  edge security, and backup, restore and upgrades. The README table maps each
  section to its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Running Keycloak With The Keycloak Operator | The Keycloak Operator |
  | 020 | Databases And Clustering | Database and clustering |
  | 030 | Edge Security | TLS termination, exposure, brute force, rate limiting |
  | 040 | Backup, Restore And Upgrades | Backup, restore and upgrades |

- **The version:** everything is written for the **Keycloak Operator 26.8.1**
  and **Keycloak 26.8.1** (`quay.io/keycloak/keycloak-operator:26.8.1`,
  `quay.io/keycloak/keycloak:26.8.1`), CR API `k8s.keycloak.org/v2beta1`, on a
  single-node `kind` cluster. Do not teach fields, flags or output from other
  versions without saying so.
- **The main sources:** the Keycloak Operator guides and the server guides on
  <https://www.keycloak.org/guides>, and the `Keycloak` CRD itself
  (`kubectl explain keycloak.spec`). Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Keycloak 26.8.1
documentation and the 26.8.1 CRD **without a live run**. No playground or lab
has been started, and no `astrona test` has passed yet. Until a maintainer runs
them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

### Terms, not metaphors

Explanations use Keycloak's, Infinispan's, PostgreSQL's, nginx's and
Kubernetes' own words. Define each one in plain technical language on first
use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Keycloak Operator | A controller that runs in the cluster and turns `Keycloak` and `KeycloakRealmImport` resources into StatefulSets, Services, Jobs and Secrets |
| `Keycloak` custom resource (CR) | The object `k8s.keycloak.org/v2beta1` `Keycloak`; its `spec` says how many instances to run, which database to use and how to reach the server |
| `KeycloakRealmImport` CR | An object that makes the operator run a one-time Job to create a realm; it never updates or deletes a realm |
| Status condition | A line in `.status.conditions` of a CR (`Ready`, `HasErrors`, `RecreateUpdateUsed`, and `Done`, `Started` on a realm import) |
| Initial admin Secret | The Secret `<cr-name>-initial-admin` that the operator creates, with `username` and `password` of a temporary administrator in `master` |
| Infinispan | The data grid library inside Keycloak that holds its caches and connects the instances into one cluster |
| Distributed / replicated / local cache | A cache whose entries live on a set number of instances / on every instance / on one instance only |
| Cache stack (`jdbc-ping`) | How instances find each other; `jdbc-ping` (the default) records each instance in a database table |
| Persistent user sessions | Keycloak 26 stores user sessions in the database by default, so they survive a restart |
| Edge termination / re-encrypt / passthrough | The proxy ends TLS and sends HTTP to Keycloak / ends TLS and opens a new TLS connection / forwards TLS untouched |
| `proxy-headers` | Tells Keycloak to read `Forwarded` (`forwarded`) or `X-Forwarded-*` (`xforwarded`) headers from the proxy |
| Brute force detection | A realm setting that locks a user out after too many failed logins |
| Rate limiting | The proxy refuses requests above a set rate, here with nginx `limit_req` |
| Update strategy | `spec.update.strategy`: `RecreateOnImageChange` (default), `Auto` or `Explicit`; decides whether the operator restarts all pods or rolls them one by one |

Do not invent friendly names for these. The product's names are what the
student meets in the CRD, the logs and the console.

### The example workloads

Every environment runs in **one namespace, `keycloak`**, because the operator
watches only the namespace it is installed in. Each playground and lab is its
own cluster, so modules never meet.

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `keycloak-operator` (Deployment) | `quay.io/keycloak/keycloak-operator:26.8.1` | The operator, installed from the `keycloak-k8s-resources` 26.8.1 manifests |
| `keycloak` (`Keycloak` CR) | `quay.io/keycloak/keycloak:26.8.1` | The operator creates the StatefulSet `keycloak` (pods `keycloak-0`, `keycloak-1`), the Service `keycloak-service` (port `8080`) and the Secret `keycloak-initial-admin` |
| `postgres` (Deployment and Service) | `postgres:17-alpine` | PostgreSQL on port `5432`, database `keycloak`, data on an `emptyDir` |
| `keycloak-db` (Secret) | | `username` `keycloak`, `password` `keycloak-db-password` |
| `inventory-secrets` (Secret) | | `alice-password` `alice-password`, used as a realm import placeholder |
| `nginx` (Deployment, Service, ConfigMap `nginx-conf`) | `nginx:1.27-alpine` | Section 030 only: the TLS-terminating reverse proxy on port `8443`, certificate in the Secret `edge-tls` |
| `tester` | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Every test request is sent from here |

Inside Keycloak, every module uses the realm `inventory`, the user `alice`
(password `alice-password`, full profile) and the public client
`inventory-cli` with **Direct access grants** on. Section 030 adds the user
`bob` (password `bob-password`) for lockout tests. The password grant is used
only so a grader can get a token from a terminal; say every time it is used
that OAuth 2.1 drops it.

### Environment facts the text must respect

- **The operator is installed from plain manifests**, namespace `keycloak`:

  ```sh
  BASE=https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.8.1/kubernetes
  kubectl apply -f $BASE/keycloaks.k8s.keycloak.org-v1.yml
  kubectl apply -f $BASE/keycloakrealmimports.k8s.keycloak.org-v1.yml
  kubectl -n keycloak apply -f $BASE/kubernetes.yml
  ```

  The documentation shows the same install as
  `kubectl apply -k 'github.com/keycloak/keycloak-k8s-resources/kubernetes?ref=26.8.1'`,
  which needs `git` on the machine. The 26.8.1 set also has CRDs for
  `KeycloakOIDCClient` and `KeycloakSAMLClient`; this course does not use them.
- **Every `Keycloak` CR in this course sets** `http.httpEnabled: true`,
  `hostname.hostname`, `ingress.enabled: false` (kind has no ingress
  controller), and `resources` of 768Mi request and 1536Mi limit. Without
  `resources`, the operator requests 1700MiB per pod, and two pods do not fit
  on a small machine.
- **Hostname.** Without a proxy, the hostname is `http://keycloak-service:8080`,
  so tokens carry the issuer `http://keycloak-service:8080/realms/inventory`.
  In section 030 it is `https://keycloak.localtest.me:8443`, and `tester`
  reaches nginx with `curl --resolve keycloak.localtest.me:8443:<nginx IP>`.
- **The administration helper** reads the generated password:

  ```sh
  ADMIN_USER=$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)
  ADMIN_PASSWORD=$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)
  kcadm() {
    kubectl -n keycloak exec -i keycloak-0 -- \
      /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
  }
  kcadm config credentials --server http://localhost:8080 --realm master --user "$ADMIN_USER" --password "$ADMIN_PASSWORD"
  ```

  Never assume the user name or the password; both come from the Secret.
- **Keycloak facts (from the 26.8.1 documentation and CRD, not yet seen on a run):**
  - The operator watches only its own namespace. Status conditions on a
    `Keycloak` CR: `Ready`, `HasErrors`, `RecreateUpdateUsed`. On a
    `KeycloakRealmImport`: `Done`, `Started`, `HasErrors`.
  - A `KeycloakRealmImport` only creates a realm that does not exist; it
    never overwrites, updates or deletes one. `spec.placeholders` maps a name
    to a Secret key, used as `${NAME}` in the realm.
  - `spec.update.strategy`: `RecreateOnImageChange` (default, downtime on an
    image change), `Auto` (rolling update for the same `major.minor` patch
    line, decided by a Job), `Explicit` (rolling update while
    `spec.update.revision` stays the same).
  - `spec.networkPolicy.enabled` defaults to `true`; the operator blocks the
    clustering ports from outside the Keycloak pods.
  - Production mode uses `cache=ispn`; the default stack is `jdbc-ping`.
    Distributed caches: `authenticationSessions`, `sessions`,
    `clientSessions`, `offlineSessions`, `offlineClientSessions`,
    `loginFailures`, `actionTokens`. Local: `realms`, `users`,
    `authorization`, `keys`, `crl`. `work` is replicated. Ports `7800` and
    `57800`. A cluster view is logged with the ID `ISPN000094`; the metric
    `vendor_cluster_size` (needs `metrics-enabled`) gives the member count.
  - User sessions are persisted in the database by default; volatile
    sessions are deprecated since 26.8. Sticky sessions give little benefit
    since 26.6.
  - Reverse proxy: edge termination needs `http-enabled=true` and
    `proxy-headers`; re-encrypt needs `proxy-headers`; passthrough needs
    `proxy-protocol-enabled=true` and no `proxy-headers`. Expose `/realms/`,
    `/resources/` and `/.well-known/`; keep `/admin/` and `/realms/master/`
    internal; never expose `/metrics`, `/health` or port `9000`.
    `proxy-trusted-addresses` limits which addresses may send proxy headers.
  - Brute force detection (realm fields, not yet checked against the
    documentation page): `bruteForceProtected`, `permanentLockout`,
    `failureFactor`, `waitIncrementSeconds`, `maxFailureWaitSeconds`,
    `maxDeltaTimeSeconds`. The lockout state of a user is at
    `attack-detection/brute-force/users/<user id>` in the Admin REST API.
- **Many environments start broken on purpose.** A lab seeds a fault in a CR,
  the nginx configuration or the database. The fault is the material. Never
  "fix" it in the bootstrap.
- **Keycloak is slow to start.** Allow up to ten minutes for the first
  `Ready` (image pulls for the operator, Keycloak and PostgreSQL).

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab | `.../labs/lab-0N/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds `config.yaml`, `README.md`, `prerequisites.md`,
`question.md`, `solution.md`, `bootstrap/01-install-operator.sh` (operator,
PostgreSQL, tester), `bootstrap/02-seed-state.sh` (the starting state),
`manifests/` (`lab-start.yaml` and the CRs the lab starts from),
`solution/apply.sh` (reference end state, only for `astrona test`),
`testing/wait-for-keycloak.sh` and `validation/validate-*.sh`.

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS093`, domain
`Production Operations, Security & Kubernetes`, weight `15`) and one entry per
section under `modules:` (`module-010` to `module-040`). Each section lists its
README, then per module the landing page, the parts with each lab (`Question`
reading plus `type: lab` entry) right after the part it tests, and the summary;
the capstone closes the section. Every lab entry has, in order: `title`, `path`,
`difficulty`, `estimated_duration`, `topic`, `task_kind`, `tags`,
`learning_goals` (2 or 3, each starting with a verb) and `resources` (1 to 4
pages on keycloak.org, the only place outside links are allowed).

- `topic`: exactly one of `operator`, `realm-import`, `database`,
  `clustering`, `edge-security`, `brute-force`, `backup-restore`, `upgrades`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below.

**Tag list** (lower case, hyphens, never synonyms):

- Operator: `keycloak-operator`, `keycloak-cr`, `realm-import`,
  `status-conditions`, `initial-admin-secret`, `placeholders`, `statefulset`,
  `resources`
- Database and clustering: `postgresql`, `db-options`, `kubernetes-secret`,
  `infinispan`, `jdbc-ping`, `instances`, `cluster-size`,
  `persistent-sessions`, `metrics`
- Edge: `reverse-proxy`, `edge-termination`, `proxy-headers`, `hostname`,
  `tls`, `exposed-paths`, `nginx`, `rate-limiting`, `brute-force`
- Backup and upgrades: `pg-dump`, `pg-restore`, `update-strategy`,
  `image-rollback`

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/section-010/module-01/playground
astrona destroy ats-093-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-093-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-093-playground-<section>-<module>`, `ats-093-lab-<section>-<module>`,
a second lab in a module `ats-093-lab-<section>-<module>-02`, and
`ats-093-capstone-<section>`.

Graders check **behaviour**: a `Ready` CR plus a real token, the issuer seen
through the proxy, a metric that counts two members, a realm that is back after
a restore. Graders also reject the plausible but wrong fix (a database
password typed into `additionalOptions`, `cache=local` to silence a cluster,
switching off the operator's network policy, exposing `/admin/` through the
proxy, deleting the damaged database instead of restoring next to it).

Test clusters on the maintainer's machine: one at a time. Two Keycloak
instances, PostgreSQL and the operator need about 6 GiB.

### Where to find trusted sources

- **Operator:** [installation](https://www.keycloak.org/operator/installation),
  [basic deployment](https://www.keycloak.org/operator/basic-deployment),
  [realm import](https://www.keycloak.org/operator/realm-import),
  [advanced configuration](https://www.keycloak.org/operator/advanced-configuration),
  [rolling updates](https://www.keycloak.org/operator/rolling-updates)
- **Server:** [caching](https://www.keycloak.org/server/caching),
  [reverse proxy](https://www.keycloak.org/server/reverseproxy),
  [hostname](https://www.keycloak.org/server/hostname),
  [database](https://www.keycloak.org/server/db),
  [configuring for production](https://www.keycloak.org/server/configuration-production)
- **High availability:** <https://www.keycloak.org/high-availability/introduction>
- **Administration:** [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html)
  (brute force detection, the Admin CLI)
- **The CRD:** `keycloaks.k8s.keycloak.org-v1.yml` in
  <https://github.com/keycloak/keycloak-k8s-resources/tree/26.8.1/kubernetes>

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
