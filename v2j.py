#!/usr/bin/env python3

import json, re, argparse

## #########################################################################
##
##  source: https://tavianator.com/the-visitor-pattern-in-python/
##
## #########################################################################
# A couple helper functions first
 
def _qualname(obj):
	"""Get the fully-qualified name of an object (including module)."""
	return obj.__module__ + '.' + obj.__qualname__
  
def _declaring_class(obj):
	"""Get the name of the class that declared an object."""
	name = _qualname(obj)
	return name[:name.rfind('.')]
  
# Stores the actual visitor methods
_methods = {}
  
# Delegating visitor implementation
def _visitor_impl(self, arg):
	"""Actual visitor method implementation."""
	tpl = (_qualname(type(self)), type(arg))
	method = None
	if tpl not in _methods.keys():
		baseclass = list(arg.__class__.__bases__)[0]
		method = _methods[(_qualname(type(self)), baseclass)]
	else:
		method = _methods[(_qualname(type(self)), type(arg))]
	return method(self, arg)
 
#The actual @visitor decorator
def visitor(arg_type):
	"""Decorator that creates a visitor method."""

	def decorator(fn):
		declaring_class = _declaring_class(fn)
		tpl = (declaring_class, arg_type)
		#print('tpl: ' + str(tpl))
		_methods[(declaring_class, arg_type)] = fn

		# Replace all decorated methods with _visitor_impl
		return _visitor_impl

	return decorator

## #########################################################################

class CstNode:
	itsType  = None
	itsNodes = []
	token = None

	def __init__(self):
		self.itsType = None
		self.itsNodes = []
		self.token = None

	def __str__(self):
		if self.itsType:
			return self.itsType
		elif self.token:
			return self.token
		else:
			return 'unknown'


class CstTopWrap(CstNode):
	def __init__(self, _root):
		self.itsNodes = []
		self.itsNodes.append(_root)

	def __str__(self):
		return 'WRAP_IGNORE_ME'


class CstUnqNameNode(CstNode):
	name = None

	def __init__(self, _name):
		self.name = _name

	def __str__(self):
		return self.name


class CstPortInputType(CstNode):
	def __str__(self):
		return 'input'


class CstPortOutputType(CstNode):
	def __str__(self):
		return 'output'


class CstPortNode(CstNode):
	portDir  = None
	portName = None

	def __init__(self, _dir, _name):
		self.portDir = _dir
		self.portName = _name
		

	def __str__(self):
		return 'PORT( ' + str(self.portDir) + " , " + str(self.portName) + ' )'


class CstContAssign(CstNode):
	lp = None
	rp = None

	def __init__(self, _lp, _rp):
		self.lp = _lp
		self.rp = _rp

	def __str__(self):
		return str(self.lp) + ' = ' + str(self.rp)

class CstModule(CstNode):
	body  = None
	name  = None
	ports = None

	def __init__(self, _name, _ports, _body):
		self.name  = _name
		self.ports = _ports
		self.body = _body[0].itsNodes

	def __str__(self):
		return 'MODULE( ' + str(self.name) + ' )'


class CstTop(CstNode):
	modules = []

	def __init__(self, _modules):
		self.modules = _modules

	def __str__(self):
		return 'Design TOP'


class CstEqAssign(CstNode):
	lp = None
	rp = None

	def __init__(self, _lp, _rp):
		self.lp = _lp
		self.rp = _rp

	def __str__(self):
		return str(self.lp) + ' = ' + str(self.rp)


class CstEdge(CstNode):
	signal = None
	edge = None

	class Xform:
		parent = None

		def __init__(self, _parent):
			self.parent = _parent

		@visitor(CstNode)
		def visit(self, node):
			for n in node.itsNodes:
				self.visit(n)

			if node.token:
				tokid, tokval = parseToken(node.token)
				if None: pass

				elif tokid == 370:
					self.parent.edge = 'POS'

		@visitor(CstUnqNameNode)
		def visit(self, node):
			self.parent.signal = node

	def __init__(self, node):
		signal = None
		edge = None

		self.Xform(self).visit(node)

	def __str__(self):
		return 'EDGE( ' + str(self.edge) + ' @ ' + str(self.signal) + ' )'


class CstDelayAssign(CstNode):
	lp = None
	rp = None

	def __init__(self, _lp, _rp):
		self.lp = _lp
		self.rp = _rp

	def __str__(self):
		return str(self.lp) + ' <= ' + str(self.rp)


class CstAlways(CstNode):
	expr = None
	block = None

	class Xform:
		parent = None

		def __init__(self, _parent):
			self.parent = _parent

		@visitor(CstNode)
		def visit(self, node):
			for n in node.itsNodes:
				self.visit(n)

		@visitor(CstEdge)
		def visit(self, node):
			self.parent.expr = node

		# FIXME: Should be more generic
		@visitor(CstDelayAssign)
		def visit(self, node):
			self.parent.block = node

	def __init__(self, node):
		self.Xform(self).visit(node)

	def __str__(self):
		return 'ALWAYS'


class CstInitial(CstNode):
	block = None

	def __init__(self, node):
		self.block = node.itsNodes[0]

	def __str__(self):
		return 'INITIAL'


class CstWire(CstNode):
	name = None
	csttype = None


	class Xform:
		parent = None

		def __init__(self, _parent):
			self.parent = _parent

		@visitor(CstNode)
		def visit(self, node):
			for n in node.itsNodes:
				self.visit(n)

			if node.token:
				tokid, tokval = parseToken(node.token)

				if None: pass

				elif tokid == 379:
					self.parent.csttype = 'reg'

		@visitor(CstUnqNameNode)
		def visit(self, node):
			self.parent.name = node.name


	def __init__(self, node):
		self.Xform(self).visit(node)

	def __str__(self):
		return 'WIRE( ' + self.csttype + ' , ' + self.name + ' )'


class CstConstant(CstNode):
	width = 0
	value = 0

	class Xform:
		parent = None

		def __init__(self, _parent):
			self.parent = _parent

		@visitor(CstNode)
		def visit(self, node):
			_ns = []
			for n in node.itsNodes:
				_r = self.visit(n)
				if _r:
					_ns.append(_r)

			if None: pass

			#elif node.itsType == 'kBaseDigits':
			#	pass

			elif node.token:
				tokid, tokval = parseToken(node.token)

				if None: pass

				elif tokid == 299: # Width
					self.parent.width = int(tokval)

				elif tokid == 306: # Value 'b
					self.parent.value = int(tokval, 2)

				elif tokid == 310: # Value 'h
					self.parent.value = int(tokval, 16)

				elif tokid == 303: # Value 'd
					self.parent.value = int(tokval, 10)

			return node


	def __init__(self, node):
		self.Xform(self).visit(node)

	def __str__(self):
		return 'CONSTANT( ' + str(self.width) + ' , ' + \
			str(self.value) + ' )'


class DumpVisitor:
	lvl = 0

	def __init__(self):
		lvl = 0

	def indent(self, lvl):
		r = ''
		for x in range(0, lvl):
			r += ' '
		return r

	@visitor(CstNode)
	def visit(self, node):
		print(self.indent(self.lvl) + str(node))

		self.lvl += 2;
		for n in node.itsNodes:
			self.visit(n)
		self.lvl -= 2

	@visitor(CstModule)
	def visit(self, node):
		print(self.indent(self.lvl) + str(node))

		self.lvl += 2;
		for n in node.ports:
			self.visit(n)
		for n in node.body:
			self.visit(n)
		self.lvl -= 2

	@visitor(CstTop)
	def visit(self, node):
		print(self.indent(self.lvl) + str(node))

		self.lvl += 2;
		for n in node.modules:
			self.visit(n)
		self.lvl -= 2

	@visitor(CstInitial)
	def visit(self, node):
		print(self.indent(self.lvl) + str(node))

		self.lvl += 2;
		self.visit(node.block)
		self.lvl -= 2

	@visitor(CstAlways)
	def visit(self, node):
		print(self.indent(self.lvl) + str(node))

		self.lvl += 2;
		self.visit(node.expr)
		self.visit(node.block)
		self.lvl -= 2


# Utils class
class Visitor:
	def visitNodes(self, node):
		newNodes = []
		for n in node.itsNodes:
			_r = self.visit(n)
			if _r:
				newNodes.append(_r)
		node.itsNodes = newNodes
		return node


def parseToken(token):
	x = re.search('^\(#(\d+):\s*"(.+)"\s*\)', token)
	if x:
		tokid  = int(x[1])
		tokval = x[2]
		return tokid, tokval
	else:
		return None, None


# Get rid of nodes with tokens of specifit id
class RemoveOrXformMiscTokens(Visitor):
	def __init__(self):
		pass

	@visitor(CstNode)
	def visit(self, node):
		if node.token:
			tokid, tokval = parseToken(node.token)
			if   tokid == 44: return None # ","
			elif tokid == 41: return None # ")"
			elif tokid == 40: return None # "("
			elif tokid == 59: return None # ";"
			elif tokid == 61: return None # "="
			elif tokid == 64: return None # "@"
			elif tokid == 695: return None # "<="
			elif tokid == 357: return None # "module", TODO: Make sure only module...
			elif tokid == 334: return None # "endmodule"
			elif tokid == 316: return None # "assign"
			elif tokid == 349: return None # "initial"
			elif tokid == 314: return None # "always"
			elif tokid == 351: return CstPortInputType()
			elif tokid == 367: return CstPortOutputType()
			elif tokid == 292: return CstUnqNameNode(tokval)

		return self.visitNodes(node)


# Remove not used (at this moment) nodes
class RemoveNotUsedNodes(Visitor):
	def __init__(self):
		pass

	@visitor(CstNode)
	def visit(self, node):
		if   node.itsType == 'kDataType': return None
		elif node.itsType == 'kUnpackedDimensions': return None

		return self.visitNodes(node)


class XformNodes(Visitor):
	@visitor(CstNode)
	def visit(self, node):
		_ns = self.visitNodes(node)

		if None: pass

		elif node.itsType == 'kPortDeclaration':
			return CstPortNode(node.itsNodes[0], node.itsNodes[1].name)

		elif node.itsType == 'kUnqualifiedId':
			return CstUnqNameNode(node.itsNodes[0].name)

		elif node.itsType == 'kDescriptionList':
			return CstTop(_ns.itsNodes)

		elif node.itsType == 'kContinuousAssignmentStatement':
			return CstContAssign(node.itsNodes[0], node.itsNodes[1])

		elif node.itsType == 'kNonblockingAssignmentStatement':
			return CstDelayAssign(node.itsNodes[0], node.itsNodes[1])

		elif node.itsType == 'kModuleDeclaration':
			header = node.itsNodes[0]
			body   = node.itsNodes[1]

			name  = header.itsNodes[0]
			ports = header.itsNodes[1]

			_body = []
			_body.append(body)
			return CstModule(name.name, ports.itsNodes[0].itsNodes, _body)

		elif node.itsType == 'kNumber':
			return CstConstant(node)

		elif node.itsType == 'kAssignmentStatement':
			return CstEqAssign(node.itsNodes[0], node.itsNodes[1])

		elif node.itsType == 'kInitialStatement':
			return CstInitial(node)

		elif node.itsType == 'kInstantiationBase':
			return CstWire(node)

		elif node.itsType == 'kEventExpression':
			return CstEdge(node)

		elif node.itsType == 'kAlwaysStatement':
			return CstAlways(node)

		# simplify
		elif len(node.itsNodes) == 1 and len(node.itsNodes[0].itsNodes) == 0:
			return node.itsNodes[0]

		return _ns


class JsonVisitor(Visitor):
	def jsonVisitNodes(self, node):
		nodes = []
		for n in node.itsNodes:
			_n = self.visit(n)
			if _n:
				nodes.append(_n)

		return nodes

	@visitor(CstNode)
	def visit(self, node):
		_r = dict()
		_r['type']  = 'AST_UNKNOWN'

		nodes = []

		for n in node.itsNodes:
			_n = self.visit(n)
			if _n:
				nodes.append(_n)

		if len(nodes):
			_r['nodes'] = nodes

		return _r

	@visitor(CstUnqNameNode)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_IDENTIFIER'
		_r['name'] = node.name
		return _r

	@visitor(CstContAssign)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_ASSIGN'
		_r['nodes'] = []
		_r['nodes'].append(self.visit(node.lp))
		_r['nodes'].append(self.visit(node.rp))
		return _r

	@visitor(CstModule)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_MODULE'
		_r['name'] = node.name

		ns = []

		for n in node.ports:
			_n = self.visit(n)
			if _n:
				ns.append(_n)

		for n in node.body:
			_n = self.visit(n)
			if _n:
				ns.append(_n)

		if len(ns):
			_r['nodes'] = ns

		return _r

	@visitor(CstPortNode)
	def visit(self, node):
		_r = dict()
		_r['port'] = str(node.portDir)
		_r['name'] = str(node.portName)
		_r['type'] = 'AST_WIRE'
		#print('J: ' + str(_r))
		return _r

	@visitor(CstTop)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_TOP'
		_ns = []
		for n in node.modules:
			_n = self.visit(n)
			if _n:
				_ns.append(_n)
		if len(_ns):
			_r['nodes'] = _ns
		return _r

	@visitor(CstTopWrap)
	def visit(self, node):
		# ignoring this node, skip to child node
		return self.visit(node.itsNodes[0])

	@visitor(CstWire)
	def visit(self, node):
		if node.csttype == 'reg':
			_r = dict()
			_r['name'] = node.name
			_r['reg'] = True
			_r['type'] = 'AST_WIRE'
			return _r

	@visitor(CstInitial)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_INITIAL'

		# Wrap in AST_BLOCK for Verilator
		_n = dict()
		_n['type'] = 'AST_BLOCK'
		_n['nodes'] = []
		_n['nodes'].append(self.visit(node.block))

		_r['nodes'] = []
		_r['nodes'].append(_n)
		return _r

	@visitor(CstEqAssign)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_ASSIGN_EQ'
		_r['nodes'] = []
		_r['nodes'].append(self.visit(node.lp))
		_r['nodes'].append(self.visit(node.rp))
		return _r

	@visitor(CstConstant)
	def visit(self, node):
		_r = dict()
		_r['type']  = 'AST_CONSTANT'
		_r['width'] = node.width
		_r['value'] = node.value
		return _r

	@visitor(CstAlways)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_ALWAYS'
		_r['nodes'] = []
		_r['nodes'].append(self.visit(node.expr))

		# Wrap in AST_BLOCK for Verilator
		_n = dict()
		_n['type'] = 'AST_BLOCK'
		_n['nodes'] = []
		_n['nodes'].append(self.visit(node.block))

		_r['nodes'].append(_n)
		return _r

	@visitor(CstEdge)
	def visit(self, node):
		_r = dict()
		if node.edge.lower() == 'pos':
			_r['type'] = 'AST_POSEDGE'
		_r['nodes'] = []
		_r['nodes'].append(self.visit(node.signal))
		return _r

	@visitor(CstDelayAssign)
	def visit(self, node):
		_r = dict()
		_r['type'] = 'AST_ASSIGN_LE'
		_r['nodes'] = []
		_r['nodes'].append(self.visit(node.lp))
		_r['nodes'].append(self.visit(node.rp))
		return _r


def parse(cst):
	cn = CstNode()

	if 'type' in cst.keys():
		cn.itsType = cst['type']

	if 'token' in cst.keys():
		cn.token = cst['token']

	if 'nodes' in cst.keys():
		for n in cst['nodes']:
			_n = parse(n)
			if _n:
				cn.itsNodes.append(_n)

	return cn


def main():
	parser = argparse.ArgumentParser(description='Verible to JSON-AST converter.')
	parser.add_argument('--input')
	parser.add_argument('--output')
	parser.add_argument('--dump1', action='store_const', const=True, default=False)
	parser.add_argument('--dump2', action='store_const', const=True, default=False)
	args = parser.parse_args()

	cst = None
	with open(args.input, 'r') as fp:
		cst = json.load(fp)

	x = CstTopWrap(parse(cst))
	RemoveOrXformMiscTokens().visit(x)
	RemoveNotUsedNodes().visit(x)
	XformNodes().visit(x)

	if args.dump1:
		DumpVisitor().visit(x)

	if args.output or args.dump2:
		jsonast = JsonVisitor().visit(x)

		if args.dump2:
			print(json.dumps(jsonast, indent=2))

		if args.output:
			with open(args.output, 'w') as fp:
				json.dump(jsonast, fp, indent=2)


if __name__ == "__main__":
	main()
