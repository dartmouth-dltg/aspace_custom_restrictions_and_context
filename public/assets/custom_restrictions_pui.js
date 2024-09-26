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
    const self = this;
    const parsedData = JSON.parse(this.searchData);

    // archival objects have an extra fragment
    if (dataUri.includes('archival_object')) {
      dataUri += '#pui'
    }
    if (parsedData[dataUri] && parsedData[dataUri]['custom_restrictions'].length > 0) {
      target.after(self.puiRestrictionTemplate(parsedData[dataUri]['custom_restrictions']))
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
