import Project from '$tl/Project/Project'
import {validateAndSanitiseSlashedPathOrThrow} from '$tl/handy/slashedPaths'
import TheatreJSTimelineInstance from '$tl/facades/TheatreJSTimelineInstance'
import { validateName } from '$tl/facades/otherSanitizers';

const projectsWeakmap = new WeakMap<TheatreJSProject, Project>()

export type TheatreJSProjectConf = Partial<{
  state: $IntentionalAny
}>

// User-facing facade for Project
export default class TheatreJSProject {
  // static name = 'Project'
  constructor(id: string, config: TheatreJSProjectConf = {}) {
    projectsWeakmap.set(this, new Project(id, config, this))
  }

  getTimeline(
    _path: string,
    instanceId: string = 'default',
  ): TheatreJSTimelineInstance {
    const path = validateAndSanitiseSlashedPathOrThrow(
      _path,
      'project.getTimeline',
    )

    validateName(instanceId, 'instanceId in project.getTimeline(path, instanceId)', true)

    return getProject(this).getTimeline(path, instanceId).facade
  }

  get adapters() {
    return getProject(this).adapters.facade
  }

  get ready() {
    return getProject(this).ready
  }

  get isReady() {
    return getProject(this).isReady()
  }
}

const getProject = (p: TheatreJSProject) =>
  (projectsWeakmap.get(p) as $IntentionalAny) as Project
