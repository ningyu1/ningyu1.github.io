---
toc : true
title : "谈一谈开发团队代码质量如何管控与提升"
description : "谈一谈开发团队代码质量如何管控与提升"
tags : [
	"代码质量管理",
	"git flow",
	"jira git",
	"code review",
	"git hook",
	"check style"
]
date : "2019-03-07 14:37:21"
categories : [
    "代码质量管理"
]
menu : "main"
---

今天我们谈一下开发团队代码质量如何做到管控与提升，我相信很多公司都会面临这样的问题，开发团队大人员技术水平参差不齐，代码写的不够规范，代码扫描问题修改太过滞后，代码库管理每个团队都不一致，偶尔还会合并丢失一些代码，code review费人费时效率不高，开发任务的管理以及任务与代码的可追溯问题，等等之类的问题，我们能否制定一套从设计到开发再到交付一整套的管控方案来帮助开发团队管控代码的质量？下来我就针对这些问题展开来谈谈我的想法。

# 举个例子

比如说我们要增加代码和任务之间的可追溯性，我们可能考虑采用git+jira关联的方式对开发人员每笔提交在提交comment中增加jira编号，这是就是一个规范，但是规范落地如何检查？开发人员如果忘记在comment中添加就会造成关联失败，那我们就要采用工具的方式帮助开发人员在提交时检查comment是否符合规范。

比如说我们有制定编码规范，也采用了sonar去扫描代码的问题，但是这个方式的缺点是太过滞后，需要质量人员跟进去推动并且效果也不是很好，我们是否可以考虑前置检查点帮助开发人员在代码编写和提交时能主动的发现问题，在代码提交的时候发现规范问题可以直接进行解决再提交，我们可以考虑采用git加checkstyle、pmd、fingbug等工具插件，在代码提交的时候进行规范检测并且进行告警，这样就可以很好的帮助开发人员及时的发现问题，并不是开发已经提交了再去sonar上检查代码规范来发现问题再事后的安排人员去解决，开发人员都有一个习惯，当功能开发好没有问题后他们很少会去主动的修改与重构代码，这样就会导致迟迟不能推进，我们提前了检查点帮助开发人员及时发现问题就可以更好的推行规范的落地。


因此我们要考虑提供一整套代码质量管理的机制，应用在开发全生命周期中，并在关键的流程节点进行验证，从而把控与提升代码的质量。

# 常见的问题及我的看法

## 静态代码扫描太滞后，推进吃力

我相信大多都会使用类似sonar这类的静态代码检查工具来检查代码，这里我们不说工具的好坏，我们只说检查问题的修复情况，我相信很多开发都会有一种习惯，在代码写完之后如果上线没有问题的话他们是很少会去主动的优化代码，即使你扫描结果告诉他他也会有各种理由推脱，当然我们可以通过管理的手段强制他们修改，比如说blocker、critical级别的必须全部改掉，其余的看情况修改，当然通过管理手段从上往下会有一定的效果，但是这些都是比较滞后的方式，我们能不能提前发现问题让开发在功能开发过程中就把发现的问题改掉？

这个当然是可以的，我们可以利用代码检查的机制，在代码开发中就让开发去扫描发现问题，在代码提交的时候去校验如果有严重的禁止代码提交。这样一来我们就可以提前来发现并解决问题，这样可能会带来的是开发人员的排斥，开发人员都觉得自己代码写的没有问题，所以这块我们需要把控这个检查规则的宽松度，我们可以结合公司的开发规范，整理不同级别的问题，通过先简后严的方式，先把开发的习惯培养起来后再逐渐的提升严格度，这样一来开发就有个适应期也比较好接受，比如说：我们通过checkstyle的规则模板定义，前期把一些无用导入包、命名不规范、导入包用*、system.out语句这类接受度高的作为error级别来推动开发适应从而培养这种良好的习惯。

## 团队Code Review没有跑起来或跑的太费事费力

在技术行业做了一定时间的人应该都知道code review是多么的重要，一可以促进团队人员之间互相交流，二可以提升整体团队的技术水平，学习优秀人员写的代码，帮助初级人员提升代码编写能力，所以code review还是强烈必须要做的，至于怎么做code review？我谈一下我的想法和建议

比较常见的方式是定期团队内组织全体人员进行集中式的code review，我比较推荐利用工具在线的操作方式来做code review，现在开源非常的火也可以参考学习开源团队code review的方式，比如说github有pull request，gitlab有merge request，可以在这个合并代码的节点上进行code review，这样做的好处是第一比较开放，只要能看到合并代码请求的都可以进行review，第二可以留下review记录，互相的想法沟通和建议可以很好的留存下来并且可以通过UI的方式友好的展示出来，从而提升code review效率。

这个当然需要结合git flow的机制来协作完成。

## 代码库分支、版本管理不规范，合并丢代码

团队多了或团队大了，每个人或多或少对git的管理与使用理解不一致，这样就造成了分支、版本管理的混乱，这样在版本代码合并时就会产生很多冲突，我们可以指定一套规范性的东西，指导开发团队进行分支、版本的管理，这里说到的是指导不是限制，要让开发在可控的范围内自由发挥。

可以参考git flow、github flow等，当然我们要统一一个工作流程推广给开发团队中。

前面我们说了用代码合并来进行code review，这样我们就要让开发人员在每开发完一个任务的时候就要进行一次代码合并，git是一个优秀的分布式代码库管理工具，我们利用git的分布式特性，以及灵活的流程机制来规范大家的使用。

例如：

一次迭代冲刺或一个版本对应一个`develop-*`分支和`release-*`，并且控制分支的push与merge权限，固定一个master分支并且控制master分支的权限，让个人开发通过`feature-{username|功能名称}-*`分支来进行功能开发，当一个任务或者一个功能开发完成进行一次`develop-*`分支的合并，这样一来及可以code review也可以有序的管理分支上的代码，当开发人员提交合并请求时发生了冲突就需要开发人员自己解决完冲突后再进行代码合并请求，这样一来版本分支上代码是有序的。

|Name|From|Remark|
|:--|:--|:--|
|`master`| - | 只能有一个并并且固定的|
|`develop-*` | 从master创建|开发分支，可以结合jira的sprint，一个sprint对应一个，迭代开始时创建，'*' 通常可以是一个发布周期或者一个冲刺命名|
|`release-*`| 从master创建|预发布分支，可以结合jira的sprint，一个sprint对应一个，迭代开始时创建，'*' 通常可以是一个发布周期或者一个冲刺命名|
|`feature-{username or 功能名称}-*` | 从`develop-*`创建|开发人员分支，这个分支的声明周期很短，在这个功能开发完成通过Merge Request发起合并进行code review之后合并从而删除分支|

以上可以定位分支约定。

具体的操作可以参考下面描述：

1. sprint开始时（需求确认后），从`master`创建`develop`分支，例如是`develop-V1.2.0`
2. 开发人员从对应的`develop`分支创建自己的`feature`分支进行开发
3. 如果`master`分支发生变更，需要从`master`分支合并到对应的`develop`分支、可以考虑定期合并一次
4. `feature`分支合并到对应的`develop`之前，需要从`develop`分支合并到`feature`分支（这个避免和其他人提交进行冲突，规范开发人员自己解决掉冲突后才能发起合并请求）
5. `feature`分支合并到对应的`develop`之后，发布到测试环境进行测试（测试环境直接使用对应的`develop`分支）
6. `develop`分支在测试环境测试通过之后，合并到对应的`release`分支并发布到预发布环境（UAT）进行测试
7. `release`分支在预发布环境（UAT）验证通过后，合并到`master`分支并发布到生产环境进行验证
8. 发布到生产环境后从`master`分支构建对应的版本tag


可同时支持多个sprint的并行。

## 代码提交备注写的很难懂甚至很随意

代码的提交备注非常重要，尤其是在合并代码时产生冲突，第一时间肯定是根据提交日期去看本次提交做了什么修改，如果说备注随便填写，或者有些都没有填这样在回头来看的时候，及时是提交本人他也不能第一时间看出具体做了哪些修改，因此我觉得作为一个开发人员提交备注写的清晰明了是一件必备的职业素养，至于一些不按照规范的技术人员我们也可以要求他们按照规范必须填写。

那如何做到对备注填写的质量把控呢？我们可以通过版本管理工具在提交代码时进行提交备注检测，比如说对长度的限制，至少要15个字符，或者对格式做一些验证，必须包含任务编号之类，这样一来就可以有效的控制代码提交备注的质量以及可读性。

我们现在常用的git就有hook机制可以提供在代码提交前后做一些钩子，利用钩子来控制允许提交或者拒绝提交，比如说git的pre-commit和commit-msg

## 开发人员的任务管理与提交代码没有关联，无法查看某个任务具体提交了哪些代码

优秀的开发人员主动性都是很好的，主动性对开发来说也是非常重要的职业素养，不要让人催促你来完成任务，自己要学会主动找任务去做主动想如何优化与提升，所以时间任务管理是非常重要的，我任务开发人员都应该具备自己的时间任务管理能力，无论用什么工具只要能管理跟踪好自己的任务就是不错的人员。

公司一般都有任务管理工具，有的用禅道、有的用jira，现在用jira的相对多一些，jira的功能丰富也可以促进团队进行敏捷的任务管理，我们可以通过打通任务管理工具和代码版本工具，让代码提交的时候通过任务编号产生关联，从而可以在任务中看到代码修改的片段。

这里我用jira+git举个例子，比如说我们利用jira做scrum的敏捷管理，在制定好epic、story、task、subtask后，可以通过scrum模型的管理手段，在开发过程中通过插件、图标的数据来分析是否有风险？那个人的任务delay？那个人的任务制定还可以再进行拆分？等，从而尽早的做出调整来控制整个迭代周期按时完成。利用git提交的备注写入jira编号，通过jira和git的插件打通任务与提交代码的关联，这样一来我们就可以很好的看到任务执行过程数据与具体改动了哪些代码，从而提升开发效率。

## 统一管理校验规则版本，由简到严循序渐进的方式提升代码质量

我们上面说到的利用了checkstyle来验证代码风格，通过git hook来控制提交备注的规范，这些都需要自定义一些脚本，这些脚本也应该利用git进行有效的管理，我们能力能做到统一的调整了规则与脚本，开发过程中的应用立即使用最新的验证规则？还有git hooks的脚本是在开发机器本地运行的，这样就带来了一个问题如何让开发去安装脚本呢？叫他们手动安装？写个bat或shell脚本让开发执行一次？

我觉得更好的方式是对开发透明在他们不知觉的时候已经悄悄的安装，我们可以利用git对规则与脚本的版本进行管理，利用nginx可以通过http方式直接访问规则与脚本文件，通过自定义maven plugin在代码build的时候验证开发机器上是否已经安装，如果没有就给它自动安装与自动更新。

这样我们只要修改了规则与脚本后进行版本发布，开发机就会自动的更新下来从而可以立即生效。

## 开发团队技术氛围低沉

很多公司开发团队一味的满头苦干，很容易忽视团队内的技术分享，再加上团队内人员进进出出有一些正能量的人当然也有一些负能量的人，这都是常事，但是不管怎样我相信做技术的人都愿意提升自己的技术能力，不管是工作中实践学习还是说参加沙龙或者论坛，都是很好的学习渠道，人的精力也是比较有限不可能关注很多面，通过团队内的技术分享，把每个人擅长的部分分享给大家，互相学习来提升凝聚力和团队整体的技术水平，这样长期以来我相信团队内的技术氛围肯定不会差。

# 总结

以上就是我对代码质量管理与提升方面的经验与思考，里面涉及到很多东西，有流程的制定、工具的协作、工具的打通、规范的制定等，因此这是一个系统性的方案，希望可以利用一整套代码质量管理的流程，在关键的流程节点来把控代码的质量，形成闭环，希望可以帮助有需要的人，如果有更好的建议也希望大家多提意见进行补充，没有完美的方式，只有找到适合的可落地的就是好的。











