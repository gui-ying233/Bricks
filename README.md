# Bricks：一个用于解析 HTML 的 Lua 模块

Bricks 是一个解析 HTML 的 Lua 模块，整体类似于JS。

半成品，心血来潮瞎写的。

## 喵一喵

```lua
local b = require('bricks')

local document = b:new('<h1 id="top" class="heading heading-1">Hello!</h1>\
<div style="margin: 0 auto;" class="container">\
	<p>\
		My name is <dfn>Bricks</dfn>, a module for parsing HTML.<br>\
		Thank you for your visit.\
	</p>\
	<p>visitors:</p>\
	<ul>\
		<li>ACandy</li>\
		<li>Bricks</li>\
		<li>Catgirl</li>\
		<li>...</li>\
	</ul>\
</div>')


local h1 = document:getElementById('top')
print(h1.id, h1.className)

local div = document:getElementsByClassName('container')[1]
print(div.style.margin)

local p = div:getElementsByTagName('p')[1]
print(p.innerHTML)

local dfn = p:getElementsByTagName('dfn')[1]
print(dfn.outerHTML)
```

输出：

```plaintext
top     heading heading-1
0 auto

                My name is <dfn>Bricks</dfn>, a module for parsing HTML.<br>
                Thank you for your visit.

<dfn>Bricks</dfn>
```

## 支持

**初始化**：`b:new()`

**获取元素**：`document:getElementsByTagName()`、`document:getElementById()`、`document:getElementsByClassName()`

**元素属性**：`ele.tagName`、`ele.outerHTML`、`ele.innerHTML`、`ele.attributes`、`ele.id`、`ele.classList`、`ele.className`、`ele.style`、`ele.dataset`、

- children 和 parentElement 需要通过 `ele:getChildren()` 和 `ele:getParentElement()` 获得，如果已经获得则也可以使用 `ele.children`、`ele.parentElement` 调用。

## 友情推荐

[ACandy](https://github.com/AmeroHan/ACandy "ACandy"): a sugary Lua module for building HTML
