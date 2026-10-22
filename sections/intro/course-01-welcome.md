# Welcome To The Course

This course trains you for the **Production Operations, Security & Kubernetes** part of the Astrona **Keycloak** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know Kubernetes well: Deployments, StatefulSets, Services, Secrets, ConfigMaps, `kubectl logs`, `kubectl describe` and `kubectl exec`. You know what a custom resource is. You have run Keycloak before and you know what a realm, a user, a client and a token are. You do not need to know the Keycloak Operator, Infinispan or nginx yet. Each new idea is explained the first time it appears.

## What you can do at the end

Running Keycloak in production is work you do on a live cluster, so this course does not ask you to remember words. It asks you to deploy Keycloak, break and fix it, and prove each fix with a real request. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **the Keycloak Operator**. You will learn to:

- Install the operator and explain what it creates for each `Keycloak` custom resource (CR).
- Write a `Keycloak` CR and read its status conditions when it does not become ready.
- Create a realm with a `KeycloakRealmImport`, with passwords taken from a Kubernetes Secret.

Every instance shares one database and talks to the others, so the second topic is **the database and clustering**. You will learn to:

- Explain what Keycloak keeps in the database and what it keeps in its Infinispan caches.
- Run two instances, prove they form one cluster, and keep a user session alive when a pod goes away.

The third topic is **edge security**. You will learn to:

- Put Keycloak behind a reverse proxy that ends TLS, with the right proxy headers and hostname.
- Decide which paths the proxy exposes, and keep the administration console private.
- Turn on brute force detection, and limit the request rate at the proxy.

The fourth topic is **backup, restore and upgrades**. You will learn to:

- Dump the database and restore it next to a damaged one.
- Upgrade Keycloak with the operator's update strategies, and roll back a failed upgrade.

Everything is written for the **Keycloak Operator 26.8.1** and **Keycloak 26.8.1**.

## The words this course uses

The pages use Keycloak's, Kubernetes' and PostgreSQL's own terms, because those are the words you meet in the custom resources, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

An **operator** is a controller that runs in the cluster and manages an application through custom resources. The **Keycloak Operator** watches `Keycloak` and `KeycloakRealmImport` resources and creates the StatefulSet, Services, Secrets and Jobs they need. A **status condition** is a line in a resource's status that says whether it is ready or has errors. **Infinispan** is the library inside Keycloak that holds its caches and joins its instances into one cluster.

The resources you will write and read most often are these:

| Resource | What it is for |
| --- | --- |
| `Keycloak` | Says how many Keycloak instances to run, which database to use and how to reach the server |
| `KeycloakRealmImport` | Creates one realm, once |
| StatefulSet `keycloak` | Runs the Keycloak pods; the operator creates and changes it, you never edit it by hand |
| Secret `keycloak-initial-admin` | The temporary administrator the operator creates |

## The example setup in your playground

Every playground and lab runs in the namespace `keycloak` on its own small cluster. The operator runs there, next to a PostgreSQL database and the `tester` pod, a client with `curl` and `jq` that sends every test request. One `Keycloak` resource, also called `keycloak`, runs one or two pods. In the edge security section, an nginx reverse proxy ends TLS in front of Keycloak.

Inside Keycloak, the pages use the same names everywhere. The application realm is `inventory`. The user `alice` signs in to it through the command-line client `inventory-cli`. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with deploying Keycloak through the operator, then makes it a cluster, then protects its edge, and ends with keeping its data safe across failures and upgrades.

| Section | What it covers |
| --- | --- |
| 010 | Running Keycloak With The Keycloak Operator |
| 020 | Databases And Clustering |
| 030 | Edge Security |
| 040 | Backup, Restore And Upgrades |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
