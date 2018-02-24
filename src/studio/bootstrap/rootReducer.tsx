import {IStoreState} from '$studio/types'
import wrapRootReducer from '$shared/utils/redux/wrapRootReducer'
import {Reducer} from '$shared/types'
import initialState from './initialState'

const mainReducer: Reducer<IStoreState, $IntentionalAny> = (
  s: IStoreState = initialState,
) => s

export default wrapRootReducer(mainReducer)