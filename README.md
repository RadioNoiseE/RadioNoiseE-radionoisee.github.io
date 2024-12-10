## Archive RNE

Built using Emacs and plan9 Mk, pure JS-free HTML5 pages.

### Prerequisites

You basically need a Emacs 29 or later and plan9 Mk. If you want to validate the generated HTMLs, you should also have HTML Tidy installed as `tidy` ~~(in order to override the obsolete one supplied by Mach-O and protected by SIP)~~.

Custom supplied scripts are `chain/web.el` for web publishing and `mkfile` for automated build.

### Build

```sh
export NPROC=16
mk publish # generate the updated HTML5 pages
mk validate # validtae all webpages under article
mk # do the above stuff
```

### Copyright

```
MIT License

Copyright (c) 2024 黄京

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
