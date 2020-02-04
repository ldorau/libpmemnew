## Basic usage:

After [building](https://github.com/ldorau/libpmemnew#how-to-build) the source, navigate to the `/build/examples/` directory. Operations include: `alloc`, `realloc`, `free`, and `print`.

 `$ ./example-template-example <file_name> [print|alloc|free|realloc] <template-example_name>`

## Options:

### Alloc:

`$ ./example-template-example <file_name> alloc <template-example_name> <size>`

Example:
```
$ ./example-template-example file alloc myArray 4
$ ./example-template-example file print myArray
    myArray = [0, 1, 2, 3]
```

### Realloc:

`$ ./example-template-example <file_name> realloc <template-example_name> <size>`

Example:
```
$ ./example-template-example file realloc myArray 7
$ ./example-template-example file print myArray
    myArray = [0, 1, 2, 3, 0, 0, 0]
```

### Free:

`$ ./example-template-example <file_name> free <template-example_name>`

Example:
```
$ ./example-template-example file free myArray
$ ./example-template-example file print myArray
    No template-example found with name: myArray
```

### Print:

`$ ./example-template-example <file_name> print <template-example_name>`

Example output can be seen in above example sections. 

