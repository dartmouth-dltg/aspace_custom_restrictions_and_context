function onPageLoad(callback) {
  let fired = false;
  const guard = () => {
    if (fired) return;
    fired = true;
    callback();
  };
  $(document).on('turbolinks:load', guard);
  $(document).ready(guard);
}

function initializeTree() {
  const repoDataEl = document.getElementById('custom-restrictions-repo-data');

  if (!repoDataEl) return;

  const { repo_uri, app_version } = JSON.parse(repoDataEl.textContent);

  if (typeof tree !== 'undefined' && typeof LargeTree !== 'undefined' && tree instanceof LargeTree) {
    new CustomRestrictionsTree(repo_uri, app_version).initialize();
  }

  if (typeof scroll !== 'undefined' && typeof InfiniteScroll !== 'undefined' && scroll instanceof InfiniteScroll) {
    new CustomRestrictionsInfiniteScroll(repo_uri, app_version).initialize();
  }

  if (typeof infiniteTree !== 'undefined' && typeof InfiniteTree !== 'undefined' && infiniteTree instanceof InfiniteTree) {
    new CustomRestrictionsInfiniteTree(repo_uri, app_version).initialize();
  }

  if (typeof infiniteRecords !== 'undefined' && typeof InfiniteRecords !== 'undefined' && infiniteRecords instanceof InfiniteRecords) {
    new CustomRestrictionsInfiniteRecords(repo_uri, app_version).initialize();
  }
}
    
class CustomRestrictionsPui {
  constructor(searchData) {
    this.searchData = searchData;
    this.searchResultsSelector = '.search-results';
    this.objectHeadingSelector = '#content h1';
  }

  puiRestrictionTemplate(data) {
    return `<span class="aspace-custom-restrictions label bg-danger badge">${data}</span>`;
  }

  decoratePuiSearch(target, dataUri) {
    if (!dataUri) {
      return;
    }
    const self = this;

    // archival objects have an extra fragment
    if (dataUri.includes('archival_object')) {
      dataUri += '#pui'
    }
    if (this.searchData[dataUri] && this.searchData[dataUri]['custom_restrictions'].length > 0) {
      target.after(self.puiRestrictionTemplate(this.searchData[dataUri]['custom_restrictions']))
    }
  }
  
  setupDecoratePuiSearch() {
    const self = this;
    $(this.searchResultsSelector).find('.recordrow').each(function iteratePuiResults() {
      const target = $(this).find('.record-title');
      const dataUri = $(this).attr('data-uri');
      self.decoratePuiSearch(target, dataUri);
    });
  }

  objectRestrictionDisplay(restriction) {
    const self = this;
    const target = $(self.objectHeadingSelector);
    target.append(self.puiRestrictionTemplate(restriction))
  }
}
