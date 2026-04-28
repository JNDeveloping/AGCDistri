import { ok } from '../../../utils/api-response.js';
import { reportService } from '../services/report.service.js';

export const getReportsSummaryController = async (req, res) => ok(res, await reportService.getSummary(req.query, req.user), 'Resumen de reportes obtenido.');
export const getReportsSalesController = async (req, res) => ok(res, await reportService.getSales(req.query, req.user), 'Reporte de ventas obtenido.');
export const getReportsProfitController = async (req, res) => ok(res, await reportService.getProfit(req.query, req.user), 'Reporte de ganancias obtenido.');
export const getReportsTopClientsController = async (req, res) => ok(res, await reportService.getTopClients(req.query, req.user), 'Ranking de clientes obtenido.');
export const getReportsTopProductsController = async (req, res) => ok(res, await reportService.getTopProducts(req.query, req.user), 'Ranking de productos obtenido.');
export const getReportsDebtController = async (req, res) => ok(res, await reportService.getDebt(req.query, req.user), 'Reporte de deuda obtenido.');
export const getReportsStockController = async (req, res) => ok(res, await reportService.getStockReport(req.query, req.user), 'Reporte de stock obtenido.');
export const getReportsPaymentsController = async (req, res) => ok(res, await reportService.getPayments(req.query, req.user), 'Reporte de pagos obtenido.');
export const getReportsZonesController = async (req, res) => ok(res, await reportService.getZones(req.query, req.user), 'Reporte por zonas obtenido.');
export const getReportsPaymentRankingController = async (req, res) => ok(res, await reportService.getPaymentRanking(req.query, req.user), 'Ranking de pagadores obtenido.');
