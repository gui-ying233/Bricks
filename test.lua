local b = require('bricks')

local document = b:new([[<h1 id="top" class="heading heading-1">Hello!</h1>
<div style="margin: 0 auto;" class="container">
	<p>
		My name is <dfn>Bricks</dfn>, a module for parsing HTML.<br>
		Thank you for your visit.
	</p>
	<p>visitors:</p>
	<ul>
		<li>ACandy</li>
		<li>Bricks</li>
		<li>Catgirl</li>
		<li>...</li>
	</ul>
</div>]])


local h1 = document:getElementById('top')
print(h1.id, h1.className)

local div = document:getElementsByClassName('container')[1]
print(div.style.margin)

local p = div:getElementsByTagName('p')[1]
print(p.innerHTML)

local dfn = p.children[1]
print(dfn.outerHTML)
