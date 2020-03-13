/**
 * Created by peteryao on 2/28/20.
 */

import {LightningElement, api} from 'lwc';

export default class BluewaveSpinner extends LightningElement {
    @api spinnerMessage;
    @api show;
}