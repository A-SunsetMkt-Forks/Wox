package util

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestStringMatcherPinyin(t *testing.T) {
	assert.True(t, IsStringMatch("有道词典", "yd", true))
	assert.True(t, IsStringMatch("网易云音乐", "yyy", true))
	assert.True(t, IsStringMatch("腾讯qq", "tx", true))
	assert.True(t, IsStringMatch("QQ音乐.app", "yinyue", true))
	assert.False(t, IsStringMatch("Microsoft Remote Desktop", "test", true))
}

func TestStringMatcher(t *testing.T) {
	testcase(t, "OverLeaf-Latex: An online LaTeX editor", "exce", false)
	testcase(t, "Windows Terminal", "term", true)
	testcase(t, "Microsoft SQL Server Management Studio", "mssms", true)
}

func testcase(t *testing.T, term string, search string, expected bool) {
	assert.Equal(t, IsStringMatch(term, search, false), expected)
}

func TestMultiplyTerms(t *testing.T) {
	terms := [][]string{{"1", "2"}}
	n := []string{"3", "4"}
	expected := [][]string{{"1", "2", "3"}, {"1", "2", "4"}}
	assert.Equal(t, expected, multiplyTerms(terms, n))
}

func TestGetPinYin(t *testing.T) {
	assert.Equal(t, []string{"Q Q yin le", "Q Q yin yue", "Q Q y l", "Q Q y y"}, getPinYin("QQ音乐"))
	assert.Equal(t, []string{"Microsoft Remote Desktop"}, getPinYin("Microsoft Remote Desktop"))
}

func TestIsStringMatchScore(t *testing.T) {
	match, score := IsStringMatchScore("有道词典", "有", true)
	assert.True(t, match)
	assert.GreaterOrEqual(t, score, int64(1))

	match, score = IsStringMatchScore("Share with AirDrop", "air", true)
	assert.True(t, match)
	assert.GreaterOrEqual(t, score, int64(1))
}

func TestIsStringMatchScoreLong(t *testing.T) {
	start := GetSystemTimestamp()
	IsStringMatchScore("X 上的 Johnny Bi：“好多推友关注清迈的物价，刚好今天和老婆去超市，随手拍了一些价格，给小伙伴们分享一下。 今天去的是Makro，是杭东这边比较大的超市，也是我们最经常去的超市，价格一般，比BigC便宜，但是和各种市场比起来偏贵。… https:/2OP” / X htt198644", "github", true)
	elapsed := GetSystemTimestamp() - start
	assert.Less(t, elapsed, int64(1000))
}
