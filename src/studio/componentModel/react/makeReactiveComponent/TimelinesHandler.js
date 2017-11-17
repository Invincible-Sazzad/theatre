// @flow
import type {TheaterJSComponent} from './index'
import * as _ from 'lodash'
import {D} from '$studio/handy'
import TimelineInstance from './TimelineInstance'
import {getPathToComponentDescriptor} from '$studio/componentModel/selectors'

export default class TimelinesHandler {
  _element: TheaterJSComponent
  _untap: () => void
  _timelineDescriptorsP: *
  _timelineDescriptorsProxy: *
  _timelineInstancesAtom: *

  constructor(element: TheaterJSComponent) {
    this._element = element
    this._timelineInstancesAtom = this._element._atom.prop('timelineInstances')

    this._timelineDescriptorsP = this._element._finalFace
      .pointer()
      .prop('timelineDescriptors')

    this._timelineDescriptorsProxy = D.derivations.autoProxyDerivedDict(
      this._timelineDescriptorsP,
      this._element.studio.ticker,
    )

    this._untap = _.noop
  }

  start() {
    this._untap = this._timelineDescriptorsProxy.changes().tap(changes => {
      changes.deletedKeys.forEach(this._removeKey)
      changes.addedKeys.forEach(this._startKey)
    })

    this._timelineDescriptorsProxy.keys().forEach(this._startKey)
  }

  _startKey = (key: string) => {
    this._timelineInstancesAtom.setProp(
      key,
      new TimelineInstance(
        this._timelineDescriptorsProxy.pointer().prop(key),
        this._element.studio,
        [
          ...getPathToComponentDescriptor(this._element.componentId),
          'timelineDescriptors',
          'byId',
          key,
        ],
      ),
    )
  }

  _removeKey = (key: string) => {
    const timelineInstance = this._timelineInstancesAtom.prop(key)
    timelineInstance.destroy()
    this._timelineInstancesAtom.deleteProp(key)
  }
}