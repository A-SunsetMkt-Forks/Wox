package plugin

import "wox/entity"

type RefreshableResult struct {
	Title           string
	SubTitle        string
	Icon            entity.WoxImage
	Preview         WoxPreview
	Tails           []QueryResultTail
	ContextData     string
	RefreshInterval int // set to 0 if you don't want to refresh this result anymore
	Actions         []QueryResultAction
}

type RefreshableResultWithResultId struct {
	ResultId        string
	Title           string
	SubTitle        string
	Icon            entity.WoxImage
	Preview         WoxPreview
	Tails           []QueryResultTail
	ContextData     string
	RefreshInterval int
	Actions         []QueryResultActionUI
}
