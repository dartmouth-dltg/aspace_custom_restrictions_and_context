class CustomRestrictionsAndContext {
  constructor(repo_id) {
    this.miniTreeLoaderSelector = '#custom-restriction-mini-tree-loader';
    this.objectTitleSelector = '.record-pane h2';
    this.auditDisplaySelector = 'div[class*="audit-display"]';
    this.miniTreeFetchedMarker = 'mini-tree-fetched';
    this.miniTreeId = '#custom-restrictions-mini-tree';
    this.basicInformation = '#basic_information';
    this.restrictionsId = '#custom-restriction';
    this.repo_id = repo_id;
    this.objectTypes = ['accessions', 'archival_objects', 'digital_objects', 'resources'];
  }

  waitForEl(selector, callback) {
    const self = this;
    if ($(selector).length) {
      callback();
    } else {
      setTimeout(() => {
        self.waitForEl(selector, callback);
      }, 100);
    }
  }

  restrictionTypeSnippet(restrictionType) {
    return `<div id="custom-restriction" class="label label-danger">${restrictionType}</div>`;
  }

  displayRestriction(restrictionType) {
    $(this.objectTitleSelector).append(this.restrictionTypeSnippet(restrictionType));
  }

  toggleMiniTree(el) {
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
    $(this.miniTreeLoaderSelector).attr('aria-expanded', 'true');
    $(this.basicInformation).before(data);
    this.moveRestrictionsLabel();
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
    });
  }

  displayMiniTreeLoader(id) {
    const self = this;
    const miniTreeLoader = AS.renderTemplate("template_custom_restrictions_context");
    $(this.objectTitleSelector).after(miniTreeLoader);
    this.fetchObjectJson(id);

    $(this.miniTreeLoaderSelector).on('click', (evt) => {
      evt.preventDefault();
      const el = evt.currentTarget;
      self.toggleMiniTree(el);
    })
  }

  fetchSearchJson(id, target, recordType) {
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
      target.append(data);
    });
  }

  decorateSearchTypes() {
    const self = this;
    $('#tabledSearchResults tbody tr').each(function findTypes() {
      if ($(this).children('td.table-record-actions').length > 0) {
        let isActionable = false
        let recordType = null;
        const editUrl = $(this).children('td.table-record-actions').find('a[href*="resolve/edit"]').attr('href');
        if (typeof editUrl !== "undefined") {
          self.objectTypes.forEach((type) => {
            if (editUrl.includes(type)) {
              isActionable = true;
              recordType = type;
            }
          });
        }

        if (isActionable) {
          const elemId = decodeURIComponent(decodeURIComponent(editUrl).split('/').slice(-1).toString());
          self.fetchSearchJson(elemId, $(this).find('td.col.title'), recordType);
        }
      }
    });
  }

  monitorTreeNav() {
    const self = this;
    $('body').on('click', '.record-title', (evt) => {
      const recordTarget = evt.currentTarget;
      const targetHref = $(recordTarget).attr('href');
      const typeAndId = targetHref.split('::').slice(-1).toString();
      const type = `${typeAndId.split("_").slice(0, -1).join("_")}s`;
      const id = typeAndId.split("_").slice(-1).toString();
      self.checkObjectStatus(type, id);
    });
  }

  checkObjectIsLoaded(type, id) {
    const self = this;
    const auditDisplay = $('div[class*="audit-display"]');
    if (auditDisplay.length) {
      const objectId = auditDisplay
        .find('input#uri')
        .attr('value')
        .split('/')
        .slice(-1)
        .toString();
    }
    if (typeof objectId !== 'undefined' && objectId === id) {
      return true;
    }
  }

  displayObjectDecoration(type, auditDisplay) {
    const objectId = $(auditDisplay).find('input#uri').attr('value').split('/').slice(-1).toString();
    this.fetchObjectJson(objectId, type);
  }

  checkObjectStatus(type, id) {
    const self = this;
    if (this.objectTypes.includes(type)) {
      if ($(this.auditDisplaySelector).length > 0 ) {
        if (id !== null && this.checkObjectIsLoaded(type, id)) {
          self.displayObjectDecoration(type, self.auditDisplaySelector);
        } else {
          this.waitForEl(this.auditDisplaySelector, () => {
            self.displayObjectDecoration(type, self.auditDisplaySelector);
          });
        }
      } else {
        this.waitForEl(this.auditDisplaySelector, () => {
          self.displayObjectDecoration(type, self.auditDisplaySelector);
        });
      }
    }
  }

  setupDecorateObjectType(type, id = null) {
    $('body').on('click', 'a.record-title', (evt) => {
      this.monitorTreeNav();
    });
    this.checkObjectStatus(type, id);
  }

}
