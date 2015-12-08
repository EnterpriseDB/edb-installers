find * -type f | grep "\.js\(m\)\?$" | cut -f1 -d":" | sed "s:^.*/::g" | sed "s:(\.min)?\.js::g" | sort -u
