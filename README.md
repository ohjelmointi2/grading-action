# Grading action

GitHub Actions action for grading an exercise repository.

```yaml
- name: Autograding
  uses: ohjelmointi2/grading-action@v0.0.1
  with:
    test_suite: ./tests.json
```

## Testing the grader locally

The folder contains an example test suite `example.json` that can be used to test the grader locally. $GITHUB_STEP_SUMMARY is expected to be set to a file path where the summary will be written.

```bash
export GITHUB_STEP_SUMMARY=./summary.md
./grade.sh example.json
```

After the script has run, the summary will be written to `summary.md`:

```bash
cat $GITHUB_STEP_SUMMARY
```
