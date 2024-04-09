class CustomRestrictionsPui {
  constructor() {
    this.searchResultsSelector = '.search-results';
    this.objectHeadingSelector = '#content h1';
    this.objectTypes = ['accessions', 'archival_objects', 'digital_objects', 'digital_object_components', 'resources'];
  }

  puiRestrictionTemplate(data) {
    return `<span class="aspace-custom-restrictions label label-danger">${data}</span>`;
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
      if (data.length > 1) {
        if (objectDisplay) {
          target.append(self.puiRestrictionTemplate(data));
        } else {
          target.after(self.puiRestrictionTemplate(data));
        }
      }
    }).fail(() => {
      console.log('Data fetch failed for Custom Restrictions and Context plugin.');
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

  setupObjectRestrictionDisplay(uri, primary_type) {
    const self = this;
    const type = `${primary_type}s`;
    if (uri.length) {
      const target = $(self.objectHeadingSelector);
      if (self.objectTypes.includes(type)) {
        self.fetchSearchJson(uri, type, target, true);
      }
    }
  }
}
