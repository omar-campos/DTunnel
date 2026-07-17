import { Render } from '../../../config/render-config';
import Authentication from '../../../middlewares/authentication';
import { FastifyRequest, FastifyReply, RouteOptions } from 'fastify';

export default {
  url: '/user',
  method: 'GET',
  // mantém autenticação normal
  onRequest: [Authentication.user],
  handler: async (req: FastifyRequest, reply: FastifyReply) => {
    // garante que o usuário esteja autenticado e tenha e-mail
    const userEmail = (req.user as any)?.email;
    const ADMIN_EMAIL = 'admin@admin.com';

    // se o e-mail não for o do admin, redireciona pra home
    if (!userEmail || userEmail.toLowerCase() !== ADMIN_EMAIL.toLowerCase()) {
      return reply.redirect('/');
    }

    // se for o admin, renderiza normalmente a página
    return Render.page(req, reply, '/user/index.html', {
      user: req.user,
      active: 'user',
      csrfToken: req.csrfProtection.generateCsrf(),
    });
  },
} as RouteOptions;
