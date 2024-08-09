# qfetter.nvim

> QuickFix list, but bETTER

A really nice feature of telescope lets you add selected entries to the quickfix list, which makes a lot of sense for the semantic of "I want to handle all of these things, once". \
However, then interacting with that qflist is pretty annoying.

You have multiple options, in terms of commands you will probably make mappings to.
`:cprev` and `:cnext` move you to the previous / next entry in the quickfix list. \
This plugin existing hints at that this is not the full story.

Actually, the first time you call `:cnext`, you end up on the _second_ entry in the quickfix list. What‽

The reason for this, is that if you're not on an entry of the qflist, the _first_ one is automatically selected. So when you call `:cnext`, vim thinks: "ah, you're currently on the first entry, and so you want to go to the next one. the _second_ one".

Which is obviously horrendously stupid! So now, to enter the quickfix list, you have to use `:cfirst` first, to get to the first entry in the list, and only then start using `:cnext` and `:cprev`. \
So immediately, your fantasy of neat two mappings is gone, as you need to handle this strange special case with (probably) another mapping.

There's another, albeit smaller, issue. \
Say you're on the last entry in the qflist (that information is displayed for you in the statusbar), and now you decide you want to go to the first one, to maybe double check something. \
The natural instinct is to use `:cnext` again — obviously, since you're on the last entry, it's just going to rotate and go to the first one, right? Wrong! You will actually get an error, if you try to do this.

Now, this behavior makes sense and is preferred, if it was some _api_, stuff that's you're supposed to be using in code. \
But vim _commands_, at least in theory, are made for interactive usage. So it's very strange to not make them behave more usefully, and instead pick correctness.

So, what does this plugin do? You get a function you can map to, that works on these rules:

1. If you're not on a qflist entry, go to the first one.
2. If you are on one, go to the next one.
3. If you're on the last one, go to the first one.

Makes sense, right? Now you have a much neater workflow, of putting something into your qflist using telescope, and then going through all the entries one by one with a hotkey (telescope is not required for this plugin, and as you'll learn later, is still useful without it).

You also have the option to make the mapping that goes _backwards_, with the same rules.

Here're my suggested mappings:

```lua
vim.keymap.set('n', ']q', function() require('qfetter').another() end)
vim.keymap.set('n', '[q', function() require('qfetter').another({ backwards = true }) end)
```

Sometimes, you might jump into a file with a bunch of qflist entries, and handle them all at once, using `:s` for example. \
At that point, pressing `]q` again and again just to get to the next file with qflist entries is slow and annoying to have to do. \
Which is why you don't have to!:

```lua
vim.keymap.set('n', ']Q', function() require('qfetter').another({ next_buffer = true }) end)
vim.keymap.set('n', '[Q', function() require('qfetter').another({ backwards = true, next_buffer = true }) end)
```

These mappings will go to the next / previous qflist entry, but only in a different _file_. \
This way, you can freely skip over all the remaining entries in a given file, and continue on to the next one easily.

I mentioned that this plugin is useful even without telescope. \
Let me paint you a picture: have you ever got the thought of "oh here's a problem at this place, but I can't handle it right now, I'm going to come back to it later".

Question: how? How are you going to get to it? With a local mark? Using [`harp-nvim`](https://github.com/Axlefublr/harp-nvim)'s local search harps? \
Regardless of your choice, now you have to come up with a register that you'll remember to check, when in reality the semantic you're trying to go for is "this is one of the places I need to eventually get to now".

```lua
vim.keymap.set('n', "'q", function() require('qfetter').mark() end)
```

This mapping will _add_ the current cursor position to the qflist (at the end). \
Don't worry, it's not buffer specific: the position includes the buffer path, so you can go ahead and collect positions throughout multiple buffers.

So now, if you see some bug you want to get to later, just add it to the qflist! \
You will then be able to use the `[q` & `q]` mappings to get to it.

> I do realize that the suggested mapping of `'q` is nonsensical and ridiculous, but I can't come up with anything better as a default. \
If you have a suggestion, feel free to share in an issue / pr. \
(Fwiw, this plugin does _not_ add any mappings for you, it's completely up to you to make them.)

You can add a location to the qflist, so it only makes sense to give you the ability to _remove_ a location from the qflist:

```lua
vim.keymap.set('n', "'Q", function() require('qfetter').unmark() end)
```

Keep this in mind: instead of removing the entry at your cursor position, it removes the "current qflist entry". \
As you go through your qflist entries, in the statusbar you'll see something like `[1 of 5]`. \
The first number is the index of the current qflist entry, and it's _that_ that's used in the `unmark()` function.

Unless you actually pass a number to the `unmark` function like `require('qfetter').unmark(3)` — this will remove the qflist entry at index 3.

If you provide a _count_ to the mapping, like `5'Q`, then that index is removed, instead of the current one. \
The `index` parameter passed to the `unmark` function still takes priority.

Added a bunch of entries, but now can't be bothered to unmark them one by one? Don't worry, there's api for that too.

```lua
vim.keymap.set('n', "''q", function() require('qfetter').clear() end)
```

As the name implies, it will fully clear the qflist.

## Setup

```lua
{
  'Axlefublr/qfetter.nvim',
  lazy = true, -- the mappings lazy-load the plugin, so it doesn't need to run at startup.
  ---@module "qfetter"
  ---@type QfetterOpts
  opts = {
    notifications = false -- stop displaying notifications on the mark(), unmark(), clear() actions. (`true` by default)
  }
}
```
