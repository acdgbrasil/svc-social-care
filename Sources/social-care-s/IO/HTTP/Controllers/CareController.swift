import Vapor

struct CareController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let patient = routes.grouped("api", "v1", "patients", ":patientId")
            .grouped(RoleGuardMiddleware("worker"))

        patient.post("appointments", use: registerAppointment)
        patient.put("intake-info", use: registerIntakeInfo)
    }

    @Sendable
    private func registerAppointment(req: Request) async throws -> Response {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(RegisterAppointmentRequest.self)
        let command = RegisterAppointmentCommand(
            patientId: patientId,
            professionalId: body.professionalId,
            summary: body.summary,
            actionPlan: body.actionPlan,
            type: body.type,
            date: body.date,
            actorId: actorId
        )
        let id = try await req.services.registerAppointment.handle(command)
        let response = StandardResponse(data: IdResponse(id: id))
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    private func registerIntakeInfo(req: Request) async throws -> HTTPStatus {
        let actorId = try req.extractActorId()
        let patientId = try req.parameters.require("patientId")
        let body = try req.content.decode(RegisterIntakeInfoRequest.self)
        let command = RegisterIntakeInfoCommand(
            patientId: patientId,
            ingressTypeId: body.ingressTypeId,
            originName: body.originName,
            originContact: body.originContact,
            serviceReason: body.serviceReason,
            linkedSocialPrograms: body.linkedSocialPrograms.map {
                .init(programId: $0.programId, observation: $0.observation)
            },
            actorId: actorId
        )
        try await req.services.registerIntakeInfo.handle(command)
        return .noContent
    }
}
