package main

import (
	"esm_bt/builder"

	"github.com/thatisuday/commando"
)

func main() {
	commando.
		SetExecutableName("esm_bt").
		SetVersion("v1.0.0").
		SetDescription("This CLI tool builds esm_arma")

	commando.
		Register("run").
		SetDescription("Builds and runs `esm_arma` on an Arma 3 Exile server").
		SetShortDescription("Builds and runs `esm_arma` on an Arma 3 Exile server").
		AddFlag(
			"use-x32,x",
			"Build the x32 version of the extension and start the x32 version of the server",
			commando.Bool,
			false).
		AddFlag(
			"target,t",
			"The target OS to build to. Valid options: windows",
			commando.String,
			"windows").
		AddFlag(
			"log-level,l",
			"Sets the log level. Valid options: error, warn, info, debug, trace",
			commando.String,
			"debug").
		AddFlag(
			"env,e",
			"Sets the env. Valid options: production, development, test",
			commando.String,
			"development").
		SetAction(func(args map[string]commando.ArgValue, flags map[string]commando.FlagValue) {
			run(args, flags)
		})

	commando.Parse(nil)
}

func run(args map[string]commando.ArgValue, flags map[string]commando.FlagValue) {
	build_tool := builder.Builder{flags}
}

// arma
// 	kill
//	start

// database
//	clean

// builder
//	
