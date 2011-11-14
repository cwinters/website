[%- META
      menu_choice = 'blog'
      page_title  = 'Sprinkle READMEs liberally' %]
<p class="post-footer align-right">
  <span class="date">October 29, 2003</span>
</p>
<h1>Sprinkle READMEs liberally</h1>

I don't know of many developer traditions as cross-platform and widespread as the <tt>README</tt> file. (Also found as <tt>README.txt</tt>) This mainly used at the project level. Just stick one in the project's root directory to give the reader some idea of what your project does, how to build it (if necessary) and possibly even how to run it. For me this is the first and most basic test of an opensource project -- if you don't have a README I won't even bother to build it. What's the point?

<p>But there's no reason we can't use that history to our advantage for other tasks. For instance, in OpenInteract2 <sup>1</sup> I put READMEs in all the 'sample/' directories to let people know their purpose. Did I have to? No, I could just rely on them to read the system documentation and learn that these files are used when creating a new website or package.</p>

<p>But good developers have a tendency to wander around the source tree to see what else is there, how it fits. Why not put the explanation as close to the encounter as possible? This lets the system reveal itself a bit at a time but still enables people to understand how the pieces fit together.</p>

<p>While you're writing something it always makes perfect sense -- you're working in that area of the system, you have its meanings and relationships loaded into your L1 cache, it all gels. But the person coming into your system fresh doesn't have this. These connections not only aren't in the cache, they're not in memory. So you tell yourself that anyone reading files in a particular directory can go to longterm storage (system docs) to find the connections to the rest of the system. But these users don't know enough to find those either! So the people using your system just kind of muddle through, hoping that enough sticks so that when they read about it later they'll be able to make the connections. Why not make life easier for these folks? (Incidentally "these folks" includes <b>you</b>, six months from now...)</p>

<p><sup>1</sup> search.cpan.org notes the special nature of READMEs by pulling them out into a separate section at the bottom of the distribution listing, see the <a href="http://search.cpan.org/~cwinters/OpenInteract-1.99_03/">OI2</a> distribution for an example.</p>

<!-- Tags: programming -->
