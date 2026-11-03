# Summary

Events, traces and a method turn the signals of health, metrics and logs into answers.

## What you learned

Login events and administration events are structured records kept in the database, off by default and per realm. They need an expiration and carry personal data. Use a metric to notice a problem and an event to find the cause. The default listener writes events to the log.

Tracing follows one request across Keycloak, the database, LDAP and other services. It is enabled with `tracing-enabled`, sends to a collector at `tracing-endpoint`, and costs enough that production samples. Trace ids in the log link the two views.

Troubleshooting goes from the outside in: the conditions of the `Keycloak` resource, the pod and its events, the container log, the dependencies, and only then one change. A pod that never started has no log; a pod that crashed has a log under `--previous`. Two mistakes can hide behind each other. The key facts to remember are these:

- Events record, metrics notice, traces locate.
- Read the status, the pod events and the log before you change anything.
- `--previous` shows the run that died.
- Change one thing at a time, and wait for `Ready`.

<!-- astrona:playground:destroy -->
