const Api = {
    resourceName: 'gypsy-inventory',

    post: function (endpoint, data = {}) {
        return fetch(`https://${this.resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).catch(err => console.error(`Api Post Error (${endpoint}):`, err));
    }
};
