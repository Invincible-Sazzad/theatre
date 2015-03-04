ComponentInjector = require '../src/ComponentInjector'

describe "ComponentInjector", ->

	c = null
	beforeEach ->
		c = new ComponentInjector

	describe "constructor()", ->

		it "should work", ->
			(-> new ComponentInjector).should.not.throw()

	describe "for global components", ->

		describe "for components already instantiated before registration", ->

			it "should have them ready", ->
				c.register "obj", obj = {}
				c.get("obj").should.equal obj

		describe "for global components not instantiated before registration", ->

			describe "with no dependencies", ->

				it "should instantiate after calling #initialize()", ->
					class A
						@type: 'global'

					c.register 'a', A
					c.initialize()
					c.get('a').should.be.instanceof A

			describe "with dependencies", ->

				it "should resolve simple dependencies", ->
					class A
						@type: 'global'
						@globalDeps: 'b': 'b'
					class B
						@type: 'global'
					c.register 'a', A
					c.register 'b', B
					c.initialize()
					expect(c.get('a').b).to.equal c.get('b')

				it "should resolve circular dependencies", ->
					class A
						@type: 'global'
						@globalDeps: 'b': 'b'
					class B
						@type: 'global'
						@globalDeps: 'a': 'a'
					c.register 'a', A
					c.register 'b', B
					c.initialize()
					expect(c.get('a').b).to.equal c.get('b')
					expect(c.get('b').a).to.equal c.get('a')

			describe "for lazy globals", ->

				it "should not instantiate on #initialize()", ->
					spy = sinon.spy()
					class A
						@type: 'global'
						@lazy: yes
						constructor: ->
							spy()

					c.register 'a', A
					c.initialize()
					spy.should.not.have.been.called

				it "should instantiate on demand", ->
					spy = sinon.spy()
					class A
						@type: 'global'
						@lazy: yes
						constructor: ->
							spy()

					c.register 'a', A
					c.initialize()
					c.get 'a'
					spy.should.have.been.calledOnce

				it "should instantiate only once", ->
					spy = sinon.spy()
					class A
						@type: 'global'
						@lazy: yes
						constructor: ->
							spy()

					c.register 'a', A
					c.initialize()
					c.get 'a'
					c.get 'a'
					spy.should.have.been.calledOnce

		describe "_constructAndInitializeGlobalClass()", ->

			it "should call constructor() of the class", ->
				cb = sinon.spy()
				class A
					@type: 'global'
					constructor: -> cb()

				c.register 'a', A
				c.initialize()
				c.get('a')
				cb.should.have.been.calledOnce

	describe "for local components", ->

		it "should not instantiate upon #initialize()", ->
			spy = sinon.spy()
			class A
				@type: 'local'
				constructor: ->
					spy()

			c.register 'a', A
			c.initialize()
			spy.should.not.have.been.called

		it "should instantiate upon #instantiate()", ->
			class A
				@type: 'local'

			c.register 'a', A
			c.instantiate('a').should.be.instanceof A

		it "should resolve their global dependencies", ->
			class A
				@type: 'local'
				@globalDeps: 'g': 'g'
			class G
				@type: 'global'
				@lazy: yes

			c.register 'a', A
			c.register 'g', G
			a = c.instantiate('a')
			expect(a.g).to.equal c.get('g')

		it "should resolve their local dependencies", ->
			class A
				@type: 'local'
				@localDeps: 'b': 'b'
			class B
				@type: 'local'

			c.register 'a', A
			c.register 'b', B
			a = c.instantiate('a')
			expect(a.b).to.be.instanceof B

		it "should detect circular dependencies in local deps", ->
			class A
				@type: 'local'
				@localDeps: 'b': 'b'
			class B
				@type: 'local'
				@localDeps: 'a': 'a'

			c.register 'a', A
			c.register 'b', B
			(-> c.instantiate('a')).should.throw()

	describe "for leech dependencies", ->

		it "should not instantiate upon #initialize()", ->
			spy = sinon.spy()
			class A
				@type: 'leech'
				@target: 'something'
				constructor: (target) ->
					spy target

			c.register 'a', A
			c.initialize()
			spy.should.not.have.been.called

		it "should instantiate upon instantiation of target", ->
			spy = sinon.spy()
			class A
				@type: 'leech'
				@target: 'b'
				constructor: (target) ->
					spy target
			class B
				@type: 'local'

			c.register 'a', A
			c.register 'b', B

			b = c.instantiate('b')
			spy.should.have.been.calledWith b

		it "should support global and local dependencies", ->
			spy = sinon.spy()
			class A
				@type: 'leech'
				@target: 'b'
				@globalDeps: {g: 'g'}
				@localDeps: {l: 'l'}
				constructor: (target) ->
					spy target
					target.leecher = this
			class B
				@type: 'local'
			class G
				@type: 'global'
			class L
				@type: 'local'

			c.register 'a', A
			c.register 'b', B
			c.register 'g', G
			c.register 'l', L

			b = c.instantiate('b')
			spy.should.have.been.calledWith b
			b.leecher.g.should.equal c.get 'g'
			b.leecher.l.should.be.instanceof L

		it "should support leeches for global components", ->

			spy = sinon.spy()

			class A
				@type: 'leech'
				@target: 'g'
				constructor: (target) ->
					spy target
					target.leecher = this

			class G
				@type: 'global'

			c.register 'a', A
			c.register 'g', G

			g = c.get('g')

			spy.should.have.been.calledWith g
			g.leecher.should.be.instanceof A

		it "should support leeches for other leeches", ->

			class L1
				@type: 'leech'
				@target: 'l2'
				constructor: (target) ->
					target.leecher = this

			class L2
				@type: 'leech'
				@target: 'g'
				constructor: (target) ->
					target.leecher = this

			class G
				@type: 'global'

			c.register 'l1', L1
			c.register 'l2', L2
			c.register 'g', G

			g = c.get('g')

			l2 = g.leecher
			l2.should.be.instanceof L2

			l1 = l2.leecher
			l1.should.be.instanceof L1

		it "should support preceding leeches", ->

			class G
				@type: 'global'

			spyA = sinon.spy()

			class A
				@type: 'leech'
				@target: 'g'
				@precedingLeeches: ['b']
				constructor: (g) ->
					spyA()

			spyB = sinon.spy()

			class B
				@type: 'leech'
				@target: 'g'
				constructor: ->
					spyB()

			c.register 'g', G
			c.register 'a', A
			c.register 'b', B

			c.get('g')
			spyA.should.have.been.calledAfter spyB