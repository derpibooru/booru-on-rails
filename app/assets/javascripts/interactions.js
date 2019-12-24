/**
 * Interactions.
 */

import { fetchJson } from './utils/requests';

const endpoints = {
  fave: `${window.booru.apiEndpoint}interactions/fave`,
  vote: `${window.booru.apiEndpoint}interactions/vote`,
  hide: `${window.booru.apiEndpoint}interactions/hide`,
};

const spoilerDownvoteMsg =
  'Neigh! - Remove spoilered tags from your filters to downvote from thumbnails';

/* Quick helper function to less verbosely iterate a QSA */
function onImage(id, selector, cb) {
  [].forEach.call(
    document.querySelectorAll(`${selector}[data-image-id="${id}"]`), cb);
}

function setScore(imageId, data) {
  onImage(imageId, '.score',
    el => el.textContent = data.score);
  onImage(imageId, '.votes',
    el => el.textContent = data.votes);
  onImage(imageId, '.favorites',
    el => el.textContent = data.favourites);
  onImage(imageId, '.upvotes',
    el => el.textContent = data.upvotes);
  onImage(imageId, '.downvotes',
    el => el.textContent = data.downvotes);
}

/* These change the visual appearance of interaction links.
 * Their classes also effect their behavior due to event delegation. */

function showUpvoted(imageId) {
  onImage(imageId, '.interaction--upvote',
    el => el.classList.add('active'));
}

function showDownvoted(imageId) {
  onImage(imageId, '.interaction--downvote',
    el => el.classList.add('active'));
}

function showFaved(imageId) {
  onImage(imageId, '.interaction--fave',
    el => el.classList.add('active'));
}

function showHidden(imageId) {
  onImage(imageId, '.interaction--hide',
    el => el.classList.add('active'));
}

function resetVoted(imageId) {
  onImage(imageId, '.interaction--upvote',
    el => el.classList.remove('active'));

  onImage(imageId, '.interaction--downvote',
    el => el.classList.remove('active'));
}

function resetFaved(imageId) {
  onImage(imageId, '.interaction--fave',
    el => el.classList.remove('active'));
}

function resetHidden(imageId) {
  onImage(imageId, '.interaction--hide',
    el => el.classList.remove('active'));
}

function interact(type, imageId, value) {
  return fetchJson('PUT', endpoints[type], {
    class: 'Image', id: imageId, value
  })
    .then(res => res.json())
    .then(res => setScore(imageId, res));
}

function displayInteractionSet(interactions) {
  interactions.forEach(i => {
    switch (i.interaction_type) {
      case 'faved':
        showFaved(i.image_id);
        break;
      case 'hidden':
        showHidden(i.image_id);
        break;
      default:
        if (i.value === 'up') showUpvoted(i.image_id);
        if (i.value === 'down') showDownvoted(i.image_id);
    }
  });
}

function loadInteractions() {

  /* Set up the actual interactions */
  displayInteractionSet(window.booru.interactions);

  /* Next part is only for image index pages
   * TODO: find a better way to do this */
  if (!document.getElementById('imagelist_container')) return;

  /* Users will blind downvote without this */
  window.booru.imagesWithDownvotingDisabled.forEach(i => {
    onImage(i, '.interaction--downvote', a => {

      // TODO Use a 'js-' class to target these instead
      const icon = a.querySelector('i') || a.querySelector('.oc-icon-small');

      icon.setAttribute('title', spoilerDownvoteMsg);
      a.classList.add('disabled');
      a.addEventListener('click', event => {
        event.stopPropagation();
        event.preventDefault();
      }, true);

    });
  });

}

const targets = {

  /* Active-state targets first */
  '.interaction--upvote.active'(imageId) {
    interact('vote', imageId, 'false')
      .then(() => resetVoted(imageId));
  },
  '.interaction--downvote.active'(imageId) {
    interact('vote', imageId, 'false')
      .then(() => resetVoted(imageId));
  },
  '.interaction--fave.active'(imageId) {
    interact('fave', imageId, 'false')
      .then(() => resetFaved(imageId));
  },
  '.interaction--hide.active'(imageId) {
    interact('hide', imageId, 'false')
      .then(() => resetHidden(imageId));
  },

  /* Inactive targets */
  '.interaction--upvote:not(.active)'(imageId) {
    interact('vote', imageId, 'up')
      .then(() => { resetVoted(imageId); showUpvoted(imageId); });
  },
  '.interaction--downvote:not(.active)'(imageId) {
    interact('vote', imageId, 'down')
      .then(() => { resetVoted(imageId); showDownvoted(imageId); });
  },
  '.interaction--fave:not(.active)'(imageId) {
    interact('fave', imageId, 'true')
      .then(() => { resetVoted(imageId); showFaved(imageId); showUpvoted(imageId); });
  },
  '.interaction--hide:not(.active)'(imageId) {
    interact('hide', imageId, 'true')
      .then(() => { showHidden(imageId); });
  },

};

function bindInteractions() {
  document.addEventListener('click', event => {

    if (event.button === 0) { // Is it a left-click?
      for (const target in targets) {
        /* Event delgation doesn't quite grab what we want here. */
        const link = event.target && event.target.closest(target);

        if (link) {
          event.preventDefault();
          targets[target](link.dataset.imageId);
        }
      }
    }

  });
}

function loggedOutInteractions() {
  [].forEach.call(document.querySelectorAll('.interaction--fave,.interaction--upvote,.interaction--downvote'),
    a => a.setAttribute('href', '/users/sign_in'));
}

function setupInteractions() {
  if (window.booru.userIsSignedIn) {
    bindInteractions();
    loadInteractions();
  }
  else {
    loggedOutInteractions();
  }
}

export { setupInteractions, displayInteractionSet };
