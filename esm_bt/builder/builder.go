package builder

import "github.com/thatisuday/commando"

type Builder struct {
	flags map[string]commando.ArgValue
}
