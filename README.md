## Website content

Run `./regen` to create the website and push it to
production. (Of course, you'll need my SSH private key to
actually push it to my site, but that's another show...)

## Dependencies

Install libxml2 (this is needed for `XML::Feed` and used by lots
of Perl XML processing, so it's a good idea to have anyway):

    sudo apt-get install libxml2 libxml2-dev

Then:

    sudo cpan install Template HTML::TagCloud XML::Feed

This will take a while because of all the dependencies.

Be sure that `ttree` from the Template module (aka, 'Template
Toolkit') is in your PATH.
