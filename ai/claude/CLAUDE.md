## Workflow

- Never perform git commits without asking.
- Always make commits through the `commit` skill, including after I approve. Never run `git commit` directly.
- Always create PRs through the `create-pull-request` skill, including after I approve. Never run `gh pr create` directly.
- Don't always assume I know what I'm talking about. If I ask you to do something, and it goes against best practices, warn me about it.
- Don't always automatically make code changes. If the prompt seems to be more of a question than a request to implement, just answer the question. You can ask if you should implement it.

## Code style

- Avoid adding docblocks unless specifically asked.
- Make sure newly created files have a trailing newline.
- Avoid self-explanatory comments. For example:
  ```
  // Do something
  this.doSomething()
  ```

## Communication

- When reporting information to me, be extremely concise and sacrifice grammar for sake of concision. Remove all mannered prose.
- When I ask for you to "give me a comment", give it to me in markdown as I would likely be copy/pasting it.

## Tooling

- Delete files or directories using `rm` without any options. It is aliased to `trash`.
- When a project uses `laravel/pao`, PHPUnit/Pest output becomes a one-line JSON summary. This is intentional — read it, don't bypass it. It already contains each failure's test name, file, assertion message, and expected/actual diff. It omits the stack trace, and its `line` is the test method's declaration line rather than the failure site. Only re-run with `PAO_DISABLE=1` when you specifically need a stack trace, and only for the failing test.
