/// <reference types="cypress" />

describe('api-test', () => {
    it('GET', () => {
        cy.request('GET', 'https://9q0daknm1d.execute-api.us-east-1.amazonaws.com/prod').then((response) => {
            expect(response).to.have.property('status', 200)
            expect(response.body).to.not.be.null
            expect(response.body).to.be.a('string')
        })        
    })
})