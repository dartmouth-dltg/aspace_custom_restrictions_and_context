class CustomRestrictionsPui {
  constructor() {
    this.searchResultsSelector = '.search-results';
    this.objectHeadingSelector = '#main-content h1';
    this.objectTypes = ['accessions', 'archival_objects', 'digital_objects', 'digital_object_components', 'resources'];
  }

  puiRestrictionTemplate(data) {
    return `<span class="label label-danger">${data}</span>`;
  }

  fetchSearchJson(dataUri, type, target, objectDisplay = false) {
    const self = this;
    $.ajax({
      url: '/aspace_custom_restrictions_and_context/pui_restrictions',
      data: {
        uri: dataUri,
        type: type,
      },
      method: 'post',
    }).done((data) => {
      if (objectDisplay) {
        target.append(self.puiRestrictionTemplate(data));
      } else {
        target.after(self.puiRestrictionTemplate(data));
      }
    });
  }
  
  setupDecoratePuiSearch() {
    const self = this;
    $(this.searchResultsSelector).find('.recordrow').each(function iteratePuiResults() {
      const dataUri = $(this).attr('data-uri');
      if (dataUri.length) {
        const target = $(this).find('.record-title');
        const type = dataUri.split("/").slice(-2, -1).join("_");
        if (self.objectTypes.includes(type)) {
          self.fetchSearchJson(dataUri, type, target);
        }
      }
    });
  }

  setupObjectRestrictionDisplay(uri) {
    const self = this;
    if (uri.length) {
      const target = $(self.objectHeadingSelector);
      const type = uri.split("/").slice(-2, -1).join("");
      if (self.objectTypes.includes(type)) {
        self.fetchSearchJson(uri, type, target, true);
      }
    }
  }
}
