/* The list of reviewable screens. The gallery, the one-at-a-time review page, Lily's notes and the
   summary page all read this file. Screen ids and variant keys are stable: notes are stored against
   them, so never rename one. When a screen changes visibly, bump its `rev` (or REVISION for all) so
   older notes are labelled as earlier-revision feedback.

   device: phone (390x844), phone-landscape (844x390), ipad (1194x834), ipad-portrait (834x1194),
           ipad-compact (507x834, Smaller iPad view at compact width; phone layout). */
window.MockRegistry = (function () {
  var REVISION = 'R5';
  var REVISION_DATE = '7 Oct 2026';

  function v(key, label, query, device) { return { key: key, label: label, query: query || '', device: device || 'phone' }; }

  var groups = [
    { id: 'home', title: 'Home', blurb: 'Your little room, with everything close by.' },
    { id: 'styleme', title: 'Style Me', blurb: 'Choose what you feel like wearing.' },
    { id: 'saved', title: 'Saved Looks', blurb: 'Outfits and pictures you want to keep.' },
    { id: 'closet', title: 'Closet, laundry and suitcases', blurb: 'Your clothes, your laundry, and what you have packed.' },
    { id: 'account', title: 'Your settings and help', blurb: 'The little details, plus help when you need it.' },
    { id: 'stylists', title: 'Stylists', blurb: 'A little outfit advice. The conversations here are examples.' },
    { id: 'shopping', title: 'Shopping ideas', blurb: 'A few ideas for finding clothes you might like.' },
    { id: 'tours', title: 'Quick tours', blurb: 'Little guides you can skip or replay whenever you like.' },
    { id: 'firstrun', title: 'Your first hello', blurb: 'What you see when you first open the app.' }
  ];

  var screens = [
    // Home
    { id: 'home', group: 'home', file: 'home.html', title: 'Home',
      desc: 'Your little room. Tap the wardrobe for clothes, the laptop for outfits, or the hamper for laundry.',
      variants: [
        v('default', 'Rainy day'),
        v('laundry-clean', 'Laundry on, all clean', '?laundry=clean'),
        v('laundry-off', 'Laundry tracking off', '?laundry=off'),
        v('sun', 'Sunny', '?weather=sun'),
        v('cloudy', 'Cloudy', '?weather=cloudy'),
        v('snow', 'Snow', '?weather=snow'),
        v('night', 'Night', '?weather=rain&time=night'),
        v('dark', 'Dark appearance', '?theme=dark&time=night'),
        v('compact-ipad', 'Smaller iPad view', '', 'ipad-compact')
      ] },
    { id: 'home-tour', group: 'tours', file: 'home-tour.html', title: 'Home quick tour', rev: 'R6',
      desc: 'A little tour of the laptop, wardrobe, suitcase and your name sign.',
      variants: [v('default', 'Laptop · Style Me', '?step=1'), v('closet', 'Wardrobe · Closet', '?step=2'),
        v('source', 'Suitcase · Packing from', '?step=3'), v('profile', 'Name sign · Profile', '?step=4'),
        v('off', 'Tour finished', '?tour=off'), v('compact-ipad', 'Smaller iPad view', '?step=1', 'ipad-compact')] },
    { id: 'home-ax', group: 'home', file: 'home-ax.html', title: 'Home at the largest text size',
      desc: 'The same home screen, with bigger words and buttons.',
      variants: [v('default', 'Largest text size'), v('dark', 'Dark appearance', '?theme=dark')] },
    { id: 'home-landscape', group: 'home', file: 'home-landscape.html', title: 'Home, iPhone sideways',
      desc: 'How your room looks when you turn your phone sideways.',
      variants: [v('default', 'iPhone landscape', '', 'phone-landscape')] },
    { id: 'ipad-home', group: 'home', file: 'ipad-home.html', title: 'Home on iPad',
      desc: 'Your room and outfit choices on an iPad.',
      variants: [v('default', 'iPad landscape', '', 'ipad'), v('dark', 'Dark appearance', '?theme=dark', 'ipad')] },
    { id: 'ipad-home-portrait', group: 'home', file: 'ipad-home-portrait.html', title: 'Home on iPad, upright',
      desc: 'Your room when you hold an iPad upright.',
      variants: [v('default', 'iPad portrait', '', 'ipad-portrait')] },

    // Style Me
    { id: 'styleme', group: 'styleme', file: 'styleme.html', title: 'Style Me request',
      desc: 'Choose what you are dressing for and which clothes you want to use.',
      variants: [
        v('default', 'Ready to style'),
        v('occasion', 'Choose an occasion', '?sheet=occasion'),
        v('occasion-other', 'Occasion: Other', '?sheet=occasion&other=1'),
        v('start', 'Choose a piece to start with', '?sheet=start'),
        v('comfort', 'Choose what feels comfortable', '?sheet=comfort'),
        v('color', 'Choose colours', '?sheet=color'),
        v('mode', 'Choose a styling option', '?sheet=mode'),
        v('strict', 'When your suitcase is empty', '?state=blocked'),
        v('offline', 'Offline', '?state=offline'),
        v('large-text', 'Largest text size', '?text=xl'),
        v('compact-ipad', 'Smaller iPad view', '', 'ipad-compact')
      ] },
    { id: 'results', group: 'styleme', file: 'results.html', title: 'Your looks',
      desc: 'Three outfit ideas. Which one feels most like you?',
      variants: [
        v('default', 'Current looks'),
        v('earlier', 'Earlier tab', '?tab=earlier'),
        v('shuffled', 'After Shuffle', '?shuffle=1'),
        v('shuffle-short', 'Shuffle with too few earlier looks', '?shuffle=1&history=short'),
        v('no-hint', 'Option B: no pictures-left hint', '?hint=off'),
        v('generating', 'Generating', '?state=generating'),
        v('partial', 'When there are only a few clothes', '?state=partial'),
        v('insufficient', 'Not enough pieces', '?state=insufficient'),
        v('failed', 'Something went wrong', '?state=failed'),
        v('offline', 'Offline', '?state=offline'),
        v('dark', 'Dark appearance', '?theme=dark'),
        v('large-text', 'Largest text size', '?text=xl'),
        v('compact-ipad', 'Smaller iPad view', '', 'ipad-compact')
      ] },
    { id: 'swap', group: 'styleme', file: 'swap.html', title: 'Swap a piece',
      desc: 'Want a different top? Pick another one here.',
      variants: [v('default', 'Swap the top')] },
    { id: 'editor', group: 'styleme', file: 'editor.html', title: 'Outfit editor',
      desc: 'Put together an outfit yourself, or change one you already like.',
      variants: [v('default', 'Editing a look'), v('new', 'Starting from scratch', '?new=1')] },
    { id: 'ipad-results', group: 'styleme', file: 'ipad-results.html', title: 'Your looks on iPad',
      desc: 'Your three outfit ideas side by side on an iPad.',
      variants: [v('default', 'iPad landscape', '', 'ipad')] },

    // Saved Looks
    { id: 'saved', group: 'saved', file: 'saved.html', title: 'Saved Looks',
      desc: 'A place to keep your favourite outfits and try-on pictures.',
      variants: [
        v('default', 'Looks'),
        v('pictures', 'Pictures', '?tab=pictures'),
        v('search', 'Search matches', '?q=navy'),
        v('search-pictures', 'Pictures search', '?tab=pictures&q=date'),
        v('no-results', 'No matches', '?q=sequins'),
        v('empty', 'Nothing saved yet', '?state=empty'),
        v('favorites', 'Option: Favorites and collections', '?view=favorites'),
        v('dark', 'Dark appearance', '?theme=dark'),
        v('compact-ipad', 'Smaller iPad view', '', 'ipad-compact')
      ] },
    { id: 'look', group: 'saved', file: 'look.html', title: 'A saved outfit',
      desc: 'Take a closer look at an outfit you saved.',
      variants: [v('default', 'Interview navy & pink'), v('no-picture', 'Without a try-on picture', '?id=weekend')] },
    { id: 'picture', group: 'saved', file: 'picture.html', title: 'Try-on picture',
      desc: 'An example of how a try-on picture could look.',
      variants: [v('default', 'Picture detail')] },
    { id: 'ipad-saved', group: 'saved', file: 'ipad-saved.html', title: 'Saved Looks on iPad',
      desc: 'Your saved outfits on an iPad.',
      variants: [v('default', 'iPad landscape', '', 'ipad')] },

    // Closet, laundry, suitcases
    { id: 'closet', group: 'closet', file: 'closet.html', title: 'Closet',
      desc: 'All your clothes in one place. Find a piece or browse around.',
      variants: [
        v('default', 'Main closet'),
        v('dirty', 'Dirty filter', '?filter=dirty'),
        v('laundry-off', 'Laundry tracking off', '?laundry=off'),
        v('empty', 'Empty closet', '?state=empty'),
        v('dark', 'Dark appearance', '?theme=dark'),
        v('large-text', 'Largest text size', '?text=xl'),
        v('compact-ipad', 'Smaller iPad view', '', 'ipad-compact')
      ] },
    { id: 'garment', group: 'closet', file: 'garment.html', title: 'A piece of clothing',
      desc: 'A closer look at one piece of clothing.',
      variants: [v('default', 'Navy dress pants')] },
    { id: 'garment-edit', group: 'closet', file: 'garment-edit.html', title: 'Add or edit a piece',
      desc: 'Add a piece with a photo, or describe it in words.',
      variants: [
        v('default', 'Choose how to add'),
        v('processing', 'Tidying up a photo (example)', '?step=processing'),
        v('review', 'Before and after', '?step=review'),
        v('details', 'Name, category and details', '?step=details'),
        v('text', 'Describe it in words', '?mode=text'),
        v('error', 'Photo could not be read', '?step=error')
      ] },
    { id: 'laundry', group: 'closet', file: 'laundry.html', title: 'Laundry',
      desc: 'Keep track of what is in the wash and what is ready to wear.',
      variants: [
        v('default', 'Two pieces in the wash'),
        v('confirm-all', 'Confirm Mark all clean', '?confirm=all'),
        v('undo', 'Undo after cleaning', '?undo=1'),
        v('off', 'Tracking off', '?laundry=off')
      ] },
    { id: 'suitcases', group: 'closet', file: 'suitcases.html', title: 'Suitcases',
      desc: 'A place for the clothes you pack for trips or keep away from home.',
      variants: [v('default', 'Three favourites'), v('all', 'See all', '?view=all'), v('none', 'No suitcases yet', '?state=empty')] },
    { id: 'suitcase', group: 'closet', file: 'suitcase.html', title: 'Inside your suitcase',
      desc: 'See what you packed, and add or take out a piece.',
      variants: [v('default', "Jose's house"), v('add', 'Add pieces', '?add=1'), v('empty', 'Empty suitcase', '?id=spring')] },
    { id: 'ipad-closet', group: 'closet', file: 'ipad-closet.html', title: 'Closet on iPad',
      desc: 'Your clothes on an iPad, with room to see each piece.',
      variants: [v('default', 'iPad landscape', '', 'ipad'), v('portrait', 'iPad portrait', '?orient=portrait', 'ipad-portrait')] },

    // Account and help
    { id: 'settings', group: 'account', file: 'settings.html', title: 'Profile and settings',
      desc: 'Your name and the little settings you can change.',
      variants: [v('default', 'Profile'), v('laundry-off', 'Track laundry turned off', '?laundry=off')] },
    { id: 'laundry-off', group: 'account', file: 'laundry-off.html', title: 'Laundry is off',
      desc: 'What you see if you choose not to keep track of laundry.',
      variants: [v('default', 'Explanation and Turn on')] },
    { id: 'fit', group: 'account', file: 'fit.html', title: 'Fit and measurements', rev: 'R6',
      desc: 'Add your measurements if you want. You can leave them blank.',
      variants: [v('default', 'Fit profile', '?version=weight-r6')] },
    { id: 'access', group: 'account', file: 'access.html', title: 'Styling access',
      desc: 'An example of where you would see how many try-on pictures you have left.',
      variants: [v('default', 'Sponsored access'), v('trial', 'Trial', '?plan=trial'), v('out', 'Out of pictures', '?plan=out')] },
    { id: 'paywall', group: 'account', file: 'paywall.html', title: 'Subscription example',
      desc: 'An example of a subscription page. This preview will never charge you.',
      variants: [v('default', 'Start free month')] },
    { id: 'packs', group: 'account', file: 'packs.html', title: 'Picture packs (demo)',
      desc: 'An example of adding more try-on pictures. Nothing here costs you money.',
      variants: [v('default', 'Picture packs'), v('out', 'Out of pictures', '?state=out')] },
    { id: 'help', group: 'account', file: 'help.html', title: 'Help',
      desc: 'Quick answers when you need a hand.',
      variants: [v('default', 'Help')] },
    { id: 'feedback', group: 'account', file: 'feedback.html', title: 'Send feedback',
      desc: 'An example of asking for help inside the app. To leave notes now, use the boxes below.',
      variants: [v('default', 'Write feedback'), v('sent', 'Sent (simulated)', '?state=sent')] },
    { id: 'privacy', group: 'account', file: 'privacy.html', title: 'Privacy and terms',
      desc: 'An example of where you would find privacy information.',
      variants: [v('default', 'Privacy and terms')] },
    { id: 'developer', group: 'account', file: 'developer.html', title: 'Demo controls',
      desc: 'Extra settings for trying out the preview. You can skip this one.',
      variants: [v('default', 'Demo controls')] },

    // Stylists
    { id: 'chat', group: 'stylists', file: 'chat.html', title: 'Ask stylist',
      desc: 'An example of chatting about an outfit. The answers are just examples for now.',
      variants: [v('default', 'Conversation')] },
    { id: 'export', group: 'stylists', file: 'export.html', title: 'Ask another stylist',
      desc: 'A way to share an outfit with someone else for advice.',
      variants: [v('default', 'Export')] },

    // Shopping
    { id: 'findone', group: 'shopping', file: 'findone.html', title: 'Find One',
      desc: 'An idea for finding a missing piece. Which place for this button feels easiest?',
      variants: [
        v('option-a', 'Idea A: beside your outfit', '?option=a'),
        v('option-b', 'Idea B: when swapping a piece', '?option=b'),
        v('results', 'Search results (simulated)', '?step=results')
      ] },
    { id: 'purchase', group: 'shopping', file: 'purchase.html', title: 'Purchase review',
      desc: 'A closer look at something you might buy. No real purchase happens here.',
      variants: [v('default', 'Review')] },
    { id: 'handoff', group: 'shopping', file: 'handoff.html', title: 'Visiting a shop',
      desc: 'An example of opening a shop and coming back to your app.',
      variants: [v('default', 'Handoff')] },
    { id: 'products', group: 'shopping', file: 'products.html', title: 'Saved products',
      desc: 'Two ideas for where to keep clothes you might want to buy.',
      variants: [v('tab', 'Option 1: third Saved Looks tab', '?option=tab'), v('profile', 'Option 2: row in Profile', '?option=profile')] },

    // Your first hello
    { id: 'onboarding', group: 'firstrun', file: 'onboarding.html', title: 'Welcome',
      desc: 'The first hello when you open your app.',
      variants: [v('default', 'Welcome')] }
  ];

  screens.push(
    { id: 'styleme-tour', group: 'tours', file: 'styleme-tour.html', title: "Style Me request \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Which clothes?", '?tip=1', 'phone'), v('tip-2', "What are your plans?", '?tip=2', 'phone'), v('tip-3', "Ready for outfit ideas?", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'results-tour', group: 'tours', file: 'results-tour.html', title: "Your looks \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Fancy another look?", '?tip=1', 'phone'), v('tip-2', "Keep a favourite", '?tip=2', 'phone'), v('tip-3', "Picture the outfit", '?tip=3', 'phone'), v('tip-4', "Change just one piece", '?tip=4', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'swap-tour', group: 'tours', file: 'swap-tour.html', title: "Swap a piece \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Which piece?", '?tip=1', 'phone'), v('tip-2', "Pick a replacement", '?tip=2', 'phone'), v('tip-3', "Keep your change", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'editor-tour', group: 'tours', file: 'editor-tour.html', title: "Outfit editor \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Give it a name", '?tip=1', 'phone'), v('tip-2', "Choose your pieces", '?tip=2', 'phone'), v('tip-3', "Keep this outfit", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'saved-tour', group: 'tours', file: 'saved-tour.html', title: "Saved Looks \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Your favourite outfits", '?tip=1', 'phone'), v('tip-2', "Your outfit pictures", '?tip=2', 'phone'), v('tip-3', "Find something quickly", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'look-tour', group: 'tours', file: 'look-tour.html', title: "A saved outfit \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Wear this one", '?tip=1', 'phone'), v('tip-2', "Make it yours", '?tip=2', 'phone'), v('tip-3', "A special favourite", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'picture-tour', group: 'tours', file: 'picture-tour.html', title: "Try-on picture \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Back to the outfit", '?tip=1', 'phone'), v('tip-2', "Keep a favourite", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'closet-tour', group: 'tours', file: 'closet-tour.html', title: "Closet \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Add your clothes", '?tip=1', 'phone'), v('tip-2', "Find a piece", '?tip=2', 'phone'), v('tip-3', "Narrow it down", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'garment-tour', group: 'tours', file: 'garment-tour.html', title: "A piece of clothing \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Change the details", '?tip=1', 'phone'), v('tip-2', "Build a look around it", '?tip=2', 'phone'), v('tip-3', "Pack it away", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'garment-edit-tour', group: 'tours', file: 'garment-edit-tour.html', title: "Add or edit a piece \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Add a photo", '?tip=1', 'phone'), v('tip-2', "Words work too", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'laundry-tour', group: 'tours', file: 'laundry-tour.html', title: "Laundry \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Which clothes?", '?tip=1', 'phone'), v('tip-2', "Fresh from the wash?", '?tip=2', 'phone'), v('tip-3', "All finished?", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'suitcases-tour', group: 'tours', file: 'suitcases-tour.html', title: "Suitcases \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Pack a little collection", '?tip=1', 'phone'), v('tip-2', "Pick your suitcase", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'suitcase-tour', group: 'tours', file: 'suitcase-tour.html', title: "Inside your suitcase \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Make the name yours", '?tip=1', 'phone'), v('tip-2', "Choose what goes in", '?tip=2', 'phone'), v('tip-3', "Style from this suitcase", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'settings-tour', group: 'tours', file: 'settings-tour.html', title: "Profile and settings \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Your name on the sign", '?tip=1', 'phone'), v('tip-2', "Help with your fit", '?tip=2', 'phone'), v('tip-3', "A little reminder", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'laundry-off-tour', group: 'tours', file: 'laundry-off-tour.html', title: "Laundry is off \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Keep track of the wash", '?tip=1', 'phone'), v('tip-2', "You can leave it off", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'fit-tour', group: 'tours', file: 'fit-tour.html', title: "Fit and measurements \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "How do you like your clothes?", '?tip=1', 'phone'), v('tip-2', "Your weight is optional", '?tip=2', 'phone'), v('tip-3', "Use the units you know", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'access-tour', group: 'tours', file: 'access-tour.html', title: "Styling access \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Your styling access", '?tip=1', 'phone'), v('tip-2', "What is left to use", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'paywall-tour', group: 'tours', file: 'paywall-tour.html', title: "Subscription example \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Read the price first", '?tip=1', 'phone'), v('tip-2', "Try the next screen", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'packs-tour', group: 'tours', file: 'packs-tour.html', title: "Picture packs (demo) \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Choose a picture pack", '?tip=1', 'phone'), v('tip-2', "See the confirmation", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'help-tour', group: 'tours', file: 'help-tour.html', title: "Help \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Find a simple answer", '?tip=1', 'phone'), v('tip-2', "Still need a hand?", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'feedback-tour', group: 'tours', file: 'feedback-tour.html', title: "Send feedback \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Tell me what happened", '?tip=1', 'phone'), v('tip-2', "See how sending works", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'privacy-tour', group: 'tours', file: 'privacy-tour.html', title: "Privacy and terms \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "You choose what to share", '?tip=1', 'phone'), v('tip-2', "Your information", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'developer-tour', group: 'tours', file: 'developer-tour.html', title: "Demo controls \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Try an offline view", '?tip=1', 'phone'), v('tip-2', "Try another kind of day", '?tip=2', 'phone'), v('tip-3', "Back to the examples", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'chat-tour', group: 'tours', file: 'chat-tour.html', title: "Ask stylist \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "The outfit we are talking about", '?tip=1', 'phone'), v('tip-2', "An easy place to start", '?tip=2', 'phone'), v('tip-3', "Ask in your own words", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'export-tour', group: 'tours', file: 'export-tour.html', title: "Ask another stylist \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Your outfit question", '?tip=1', 'phone'), v('tip-2', "Choose what goes with it", '?tip=2', 'phone'), v('tip-3', "Take your question with you", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'findone-tour', group: 'tours', file: 'findone-tour.html', title: "Find One \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Looking for one piece?", '?tip=1', 'phone'), v('tip-2', "See some ideas", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'purchase-tour', group: 'tours', file: 'purchase-tour.html', title: "Purchase review \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Check the fit", '?tip=1', 'phone'), v('tip-2', "Keep it for later", '?tip=2', 'phone'), v('tip-3', "Visit the shop", '?tip=3', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'handoff-tour', group: 'tours', file: 'handoff-tour.html', title: "Visiting a shop \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "The shop you chose", '?tip=1', 'phone'), v('tip-2', "Did you buy it?", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'products-tour', group: 'tours', file: 'products-tour.html', title: "Saved products \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Things you might buy", '?tip=1', 'phone'), v('tip-2', "Find a saved piece", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'onboarding-tour', group: 'tours', file: 'onboarding-tour.html', title: "Welcome \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Hello, Lily", '?tip=1', 'phone'), v('tip-2', "Already been here?", '?tip=2', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'home-ax-tour', group: 'tours', file: 'home-ax-tour.html', title: "Home at the largest text size \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Style Me", '?tip=1', 'phone'), v('tip-2', "Your closet", '?tip=2', 'phone'), v('tip-3', "Your suitcase", '?tip=3', 'phone'), v('tip-4', "That is you", '?tip=4', 'phone'), v('off', 'Tour finished', '?tour=off', 'phone')] },
    { id: 'home-landscape-tour', group: 'tours', file: 'home-landscape-tour.html', title: "Home, iPhone sideways \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Style Me", '?tip=1', 'phone-landscape'), v('tip-2', "Your closet", '?tip=2', 'phone-landscape'), v('tip-3', "Your suitcase", '?tip=3', 'phone-landscape'), v('tip-4', "That is you", '?tip=4', 'phone-landscape'), v('off', 'Tour finished', '?tour=off', 'phone-landscape')] },
    { id: 'ipad-home-tour', group: 'tours', file: 'ipad-home-tour.html', title: "Home on iPad \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Style Me", '?tip=1', 'ipad'), v('tip-2', "Your closet", '?tip=2', 'ipad'), v('tip-3', "Your suitcase", '?tip=3', 'ipad'), v('tip-4', "That is you", '?tip=4', 'ipad'), v('off', 'Tour finished', '?tour=off', 'ipad')] },
    { id: 'ipad-home-portrait-tour', group: 'tours', file: 'ipad-home-portrait-tour.html', title: "Home on iPad, upright \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Style Me", '?tip=1', 'ipad-portrait'), v('tip-2', "Your closet", '?tip=2', 'ipad-portrait'), v('tip-3', "Your suitcase", '?tip=3', 'ipad-portrait'), v('tip-4', "That is you", '?tip=4', 'ipad-portrait'), v('off', 'Tour finished', '?tour=off', 'ipad-portrait')] },
    { id: 'ipad-results-tour', group: 'tours', file: 'ipad-results-tour.html', title: "Your looks on iPad \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Fancy another look?", '?tip=1', 'ipad'), v('tip-2', "Keep a favourite", '?tip=2', 'ipad'), v('tip-3', "Picture the outfit", '?tip=3', 'ipad'), v('off', 'Tour finished', '?tour=off', 'ipad')] },
    { id: 'ipad-saved-tour', group: 'tours', file: 'ipad-saved-tour.html', title: "Saved Looks on iPad \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Your favourite outfits", '?tip=1', 'ipad'), v('tip-2', "Your outfit pictures", '?tip=2', 'ipad'), v('tip-3', "Find something quickly", '?tip=3', 'ipad'), v('off', 'Tour finished', '?tour=off', 'ipad')] },
    { id: 'ipad-closet-tour', group: 'tours', file: 'ipad-closet-tour.html', title: "Closet on iPad \u00b7 quick tour", rev: 'R6',
      desc: 'A few easy tips. Next shows another tip; Skip lets you explore.', variants: [v('default', "Add your clothes", '?tip=1', 'ipad'), v('tip-2', "Find a piece", '?tip=2', 'ipad'), v('tip-3', "A closer look", '?tip=3', 'ipad'), v('off', 'Tour finished', '?tour=off', 'ipad')] }
  );
  screens.find(function (s) { return s.id === "settings"; }).rev = "R6";

  screens.forEach(function (s) { if (['picture','saved','look','ipad-saved','picture-tour','saved-tour','look-tour','ipad-saved-tour'].indexOf(s.id) >= 0) { s.rev = 'R7'; s.livePreview = true; } });

  screens.forEach(function (s) { if (s.id === 'settings' || s.id === 'settings-tour') { s.rev = 'R8'; s.livePreview = true; }
    if (s.id === 'settings') s.variants.push(v('tryon-photo', 'Choose your try-on photo', '?sheet=tryon-photo'), v('tryon-picker', 'Example photo choice', '?sheet=tryon-photo&view=picker'), v('tryon-added', 'Photo added', '?sheet=tryon-photo&photo=added'));
  });

  // Start review with every guide, then continue through the regular app screens.
  // Keep IDs, variants and revisions stable so existing notes stay attached.
  groups = groups.filter(function (g) { return g.id === 'tours'; }).concat(groups.filter(function (g) { return g.id !== 'tours'; }));
  screens = screens.filter(function (s) { return s.group === 'tours'; }).concat(screens.filter(function (s) { return s.group !== 'tours'; }));

  screens.forEach(function (s) { if (['home','home-tour','ipad-home','ipad-home-tour','ipad-closet','ipad-closet-tour','ipad-results','ipad-results-tour','ipad-saved','ipad-saved-tour'].indexOf(s.id)>=0) { s.rev='R9'; s.livePreview=true; } });

  screens.forEach(function(s) { if (!/^ipad-|^home/.test(s.id)) { s.rev='R11'; s.livePreview=true; } });

  screens.forEach(function(s) {
    if (!/^ipad-|^home-ax|^home-landscape/.test(s.id)) s.variants.push(v('ipad-landscape','On iPad, sideways',s.variants[0].query,'ipad'));
  });

  var sizes = {
    'phone': { w: 390, h: 844, label: 'iPhone' },
    'phone-landscape': { w: 844, h: 390, label: 'iPhone sideways' },
    'ipad': { w: 1194, h: 834, label: 'iPad' },
    'ipad-portrait': { w: 834, h: 1194, label: 'iPad upright' },
    'ipad-compact': { w: 507, h: 834, label: 'Smaller iPad view' }
  };

  function revOf(screen) { return screen.rev || REVISION; }
  function flat() {
    var list = [];
    screens.forEach(function (s) { s.variants.forEach(function (vv) { list.push({ screen: s, variant: vv }); }); });
    return list;
  }
  return { REVISION: REVISION, REVISION_DATE: REVISION_DATE, groups: groups, screens: screens, sizes: sizes, revOf: revOf, flat: flat };
})();
