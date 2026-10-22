# Section 020: Databases And Clustering

One Keycloak pod is a single point of failure. Two pods remove it, but only if they behave as one server: a user who signs in through one pod must stay signed in when the next request lands on the other. Keycloak gets there with two pieces that work together. The database holds everything that must survive, and Infinispan, the library inside Keycloak that holds its caches, joins the pods into one cluster.

This section explains which data lives where, how the pods find each other, and how to prove that they really are one cluster and not two servers that happen to share a database.

## What you will learn

- What Keycloak stores in the database, including user sessions, and what it keeps only in its caches.
- The database settings of the `Keycloak` resource, and the connection pool.
- The three kinds of Infinispan cache (local, distributed and replicated) and which Keycloak caches are which.
- How instances find each other with the default `jdbc-ping` stack, and which ports and network policy they need.
- Proving a cluster with the `ISPN000094` log line and the `vendor_cluster_size` metric.
- Keeping a user session alive when a pod is deleted.

## The learning path

The section has one module. It has a landing page, two short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground: a cluster where the operator runs Keycloak with two instances on PostgreSQL.

### 1. Run Keycloak As A Cluster

1. The Database Is The Source Of Truth
2. Infinispan Caches And Cluster Discovery, followed by the lab **Join Two Keycloak Instances Into One Cluster**
3. Summary

## Section capstone: Keep Sessions Alive Through A Pod Restart

The capstone starts with a Keycloak that cannot survive the loss of a pod, for more than one reason. You make it a cluster of two instances that keeps a user's session when the grader deletes a pod. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-093-capstone-020
```
