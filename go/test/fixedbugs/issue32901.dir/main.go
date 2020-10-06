// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import "./c"
import "reflect"

func main() {
	x := c.F()
	p := c.P()
	t := reflect.PtrTo(reflect.TypeOf(x))
	tp := reflect.TypeOf(p)
	if t != tp {
		panic("FAIL")
	}
}
