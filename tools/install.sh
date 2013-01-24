#!/usr/bin/env bash

if [[ ! -d ~/bin ]]; then
	mkdir ~/bin
fi


echo '#!/usr/bin/env bash

/Applications/swf2png.app/Contents/MacOS/swf2png "$@"' > ~/bin/swf2png

chmod +x ~/bin/swf2png

echo 'Done! Make sure you have got ~/bin in your PATH variable'