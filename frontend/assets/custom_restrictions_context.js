class CustomRestrictionsAndContext {
  constructor(repo_id, displayContext = true, searchData = null) {
    this.searchRestrictionsData = searchData;
    this.miniTreeLoaderSelector = '#custom-restriction-mini-tree-loader';
    this.objectTitleSelector = '.record-pane h2';
    this.auditDisplaySelector = 'div[class*="audit-display"]';
    this.miniTreeFetchedMarker = 'mini-tree-fetched';
    this.miniTreeId = '#custom-restrictions-mini-tree';
    this.basicInformation = '#basic_information';
    this.restrictionsId = '#custom-restriction';
    this.repo_id = repo_id;
    this.displayContext = displayContext;
    this.objectTypes = ['accessions', 'archival_objects', 'digital_objects', 'digital_object_components', 'resources'];
  }

  restrictionTypeSnippet(restrictionType) {
    return `<div id="custom-restriction" class="label label-danger">${restrictionType}</div>`;
  }

  displayRestriction(restrictionType) {
    $(this.objectTitleSelector).append(this.restrictionTypeSnippet(restrictionType));
  }

  toggleMiniTree() {
    const el = this.miniTreeLoaderSelector;
    const miniTree = $(this.miniTreeId);
    const miniTreeControl = $(el);
    if (miniTreeControl.attr('aria-expanded') === 'false') {
      miniTree.show();
      miniTreeControl.attr('aria-expanded', 'true');
    } else {
      miniTree.hide();
      miniTreeControl.attr('aria-expanded', 'false');
    }
  }

  moveRestrictionsLabel() {
    $(this.objectTitleSelector).append($(this.restrictionsId));
  }

  addMiniTree(data) {
    const hasContext = $(data).find('#mini-tree-context').length > 0;
    const hasLocation = $(data).find('.mini-tree-location').length > 0
    if (hasContext === false) {
      $(this.miniTreeLoaderSelector).replaceWith(AS.renderTemplate("template_custom_restrictions_location_only"));
    }
    if (hasLocation === false) {
      $(this.miniTreeLoaderSelector).replaceWith(AS.renderTemplate("template_custom_restrictions_context_only"));
    }
    if (hasLocation === false && hasContext == false) {
      $(this.miniTreeLoaderSelector).remove();
    }
    $(this.basicInformation).before(data);
    this.moveRestrictionsLabel();

    if (this.displayContext) {
      $(this.miniTreeLoaderSelector).attr('aria-expanded', 'true');
    }
  }

  removeMiniTreeToggle() {
    $(this.miniTreeLoaderSelector).remove();
  }

  fetchObjectJson(id, recordType = 'archival_objects') {
    const self = this;
    $.ajax({
      url: '/plugins/aspace_custom_restrictions_and_context/mini_tree',
      data: {
        id: id,
        repo_id: self.repo_id,
        type: recordType,
      },
      method: 'post',
    }).done((data) => {
      self.addMiniTree(data);
    }).fail(() => {
      self.removeMiniTreeToggle();
    });
  }

  displayMiniTreeToggle() {
    const self = this;

    if (this.displayContext) {
      const miniTreeLoader = AS.renderTemplate("template_custom_restrictions_context_and_location");
      $(this.objectTitleSelector).after(miniTreeLoader);

      $('body').on('click', this.miniTreeLoaderSelector, (evt) => {
        evt.preventDefault();
        self.toggleMiniTree();
      })
    }
  }

  displaySearchEnhancements(id, target) {
    const self = this;    
    const restrictionData = JSON.parse(this.searchRestrictionsData)[`${id}`];

    if (typeof restrictionData === 'undefined') {
      return;
    }
    const crTemplate = AS.renderTemplate("template_custom_restrictions_search_enhance", {
      restrictions: restrictionData['custom_restrictions'],
      locations: restrictionData['custom_locations']
    });

    target.append(crTemplate);
  }

  decorateSearchTypes() {
    const self = this;
    $('#tabledSearchResults tbody tr').each(function findTypes() {
      if ($(this).children('td.table-record-actions').length > 0) {
        let isActionable = false
        let recordType = null;
        const viewUrl = $(this).children('td.table-record-actions').find('a[href*="resolve/readonly"]').attr('href');
        if (typeof viewUrl !== "undefined") {
          self.objectTypes.forEach((type) => {
            if (viewUrl.includes(type)) {
              isActionable = true;
              recordType = type;
            }
          });
        }

        if (isActionable) {
          const target = $(this).children('td.title');
          const elemId = new URLSearchParams(viewUrl.split('?').slice(-1).join('')).get('uri');
          self.displaySearchEnhancements(elemId, target);
        }
      }
    });
  }

}
